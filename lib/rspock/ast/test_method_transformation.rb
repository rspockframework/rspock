# frozen_string_literal: true

require 'ast_transform/abstract_transformation'
require 'rspock/ast/node'
require 'rspock/ast/statement_to_assertion_transformation'
require 'rspock/ast/header_nodes_transformation'
require 'rspock/ast/interaction_to_mocha_mock_transformation'
require 'rspock/ast/interaction_to_block_identity_assertion_transformation'
require 'rspock/ast/test_method_def_transformation'
require 'rspock/ast/parser/test_method_parser'

module RSpock
  module AST
    class TestMethodTransformation < ASTTransform::AbstractTransformation
      def initialize(block_registry, strict: true)
        @parser = Parser::TestMethodParser.new(block_registry, strict: strict)
        @statement_transformation = StatementToAssertionTransformation.new
      end

      def run(node)
        rspock_ast = @parser.parse(node)
        return node if rspock_ast.nil?
        transform(rspock_ast)
      end

      private

      def transform(rspock_ast)
        method_call = rspock_ast.def_node.method_call
        method_args = rspock_ast.def_node.args
        where = rspock_ast.where_node

        body = build_test_body(rspock_ast.body_node)
        build_ruby_ast(method_call, method_args, body, where)
      end

      # --- Test body assembly ---
      #
      # Statements are assembled in SOURCE order so line-aligned emission keeps each one on its own line.
      # Execution-order requirements that source order cannot express (interaction setups in Then must run before the
      # When body they observe) are carried by ast-transform's thunk facility (run_after / thunk) instead of by
      # textual hoisting.
      def build_test_body(body_node)
        blocks = body_node.children
        sections = blocks.map { |block_node| transform_block(block_node) }

        when_statements = statements_of_type(blocks, sections, :rspock_when)
        cleanup_statements = statements_of_type(blocks, sections, :rspock_cleanup)
        interaction_setups = sections.flat_map(&:interaction_setups)
        raises_node = blocks.filter_map { |block_node| find_raises(block_node) }.first

        source_order = blocks.zip(sections).flat_map do |block_node, section|
          next [] if block_node.type == :rspock_cleanup

          section.statements.reject { |statement| statement.type == :rspock_raises }
        end

        body_children = order_execution(source_order, when_statements, interaction_setups, raises_node)

        ast = s(:begin, *body_children)
        cleanup_statements.empty? ? ast : s(:kwbegin, s(:ensure, ast, s(:begin, *cleanup_statements)))
      end

      Section = Data.define(:statements, :interaction_setups)

      def transform_block(block_node)
        case block_node.type
        when :rspock_then, :rspock_expect
          transform_assertion_block(block_node)
        else
          Section.new(statements: block_node.children, interaction_setups: [])
        end
      end

      # Then/Expect children become plain Ruby in place: interactions lower to Mocha setups anchored at the
      # interaction's own source line (plus an identity assertion for &block forwarding), statements become
      # assertions at their own lines.
      #
      # Within the section, ALL setups come before all assertions: the thunked When body executes right after the
      # last setup, and every assertion (identity or otherwise) observes the When body's effects, so none may
      # precede that point. Setups keep source order and their anchors, so alignment holds; assertions after them
      # are either synthetic (identity assertions, loc-less, pack anywhere) or textually below the interactions in
      # the common case.
      def transform_assertion_block(block_node)
        setups = []
        assertions = []
        interaction_index = 0

        block_node.children.each do |child|
          case child.type
          when :rspock_interaction
            interaction_setups, identity_assertions = lower_interaction(child, interaction_index)
            interaction_index += 1
            setups.concat(interaction_setups)
            assertions.concat(identity_assertions)
          when :rspock_binary_statement, :rspock_statement
            assertions << anchored_at(child, @statement_transformation.run(child))
          else
            assertions << child
          end
        end

        Section.new(statements: setups + assertions, interaction_setups: setups)
      end

      # @return [Array(Array, Array)] Mocha setup statements, identity assertions
      def lower_interaction(interaction, index)
        setup = InteractionToMochaMockTransformation.new(index).run(interaction)
        assertion = InteractionToBlockIdentityAssertionTransformation.new(index).run(interaction)

        setups = setup.type == :begin ? setup.children.dup : [setup]
        setups[0] = anchored_at(interaction, setups[0])

        [setups, assertion.equal?(interaction) ? [] : [assertion]]
      end

      # Reorders execution (not text) where required:
      # - interactions without raises: run the When body after the last interaction setup (run_after — the paved
      #   road).
      # - raises without interactions: the When body inlines directly into assert_raises; no thunk needed.
      # - raises with interactions: the When body is thunked into the assert_raises block inserted after the last
      #   setup; the lowering re-emits the body at its own source lines.
      def order_execution(source_order, when_statements, interaction_setups, raises_node)
        if raises_node
          build_raises_body(source_order, when_statements, interaction_setups, raises_node)
        elsif interaction_setups.any? && when_statements.any?
          run_after(source_order, run: when_statements, after: interaction_setups.last)
        else
          source_order
        end
      end

      def build_raises_body(source_order, when_statements, interaction_setups, raises_node)
        if interaction_setups.any?
          assertion = build_assert_raises(raises_node, thunk(*when_statements))

          reordered = replace_run(source_order, when_statements, [])
          insert_after(reordered, interaction_setups.last, assertion)
        else
          when_body = when_statements.length == 1 ? when_statements[0] : s(:begin, *when_statements)
          assertion = build_assert_raises(raises_node, when_body)

          replace_run(source_order, when_statements, [assertion])
        end
      end

      def build_assert_raises(raises_node, body)
        assert_raises_call = s(:block,
          s(:send, nil, :assert_raises, raises_node.exception_class),
          s(:args),
          body
        )

        if raises_node.capture_name
          s(:lvasgn, raises_node.capture_name, assert_raises_call)
        else
          assert_raises_call
        end
      end

      def find_raises(block_node)
        return nil unless block_node.type == :rspock_then

        block_node.children.find { |child| child.type == :rspock_raises }
      end

      def statements_of_type(blocks, sections, type)
        blocks.zip(sections)
          .select { |block_node, _section| block_node.type == type }
          .flat_map { |_block_node, section| section.statements }
      end

      # --- Identity-based sequence edits (non-thunk counterparts of run_after) ---

      def replace_run(statements, run, replacement)
        start = statements.index { |statement| statement.equal?(run.first) }
        raise ArgumentError, "run is not part of statements" unless start

        result = statements.dup
        result[start, run.length] = replacement
        result
      end

      def insert_after(statements, anchor, insertion)
        index = statements.index { |statement| statement.equal?(anchor) }
        raise ArgumentError, "anchor is not part of statements" unless index

        result = statements.dup
        result.insert(index + 1, insertion)
        result
      end

      # Re-anchors +node+ at +anchor+'s source location so emission places it on the anchor's line.
      # No-op for anchors without locations.
      def anchored_at(anchor, node)
        return node unless anchor.loc&.expression

        s_at(anchor, node.type, *node.children)
      end

      # --- Build final Ruby AST ---

      def build_ruby_ast(method_call, method_args, body_node, where)
        if where
          test_def = anchored_at(method_call, s(:block,
            TestMethodDefTransformation.new.run(method_call),
            method_args,
            body_node
          ))
          test_def = HeaderNodesTransformation.new(where.header).run(test_def)

          s(:block,
            build_where_iterator(where.data_rows),
            build_where_args(where.header),
            test_def
           )
        else
          anchored_at(method_call, s(:block,
            method_call,
            method_args,
            body_node
          ))
        end
      end

      # --- Where block helpers ---
      #
      # Each data row carries its source line as a trailing element, surfaced in the generated test NAME only
      # (uniqueness for identical rows + the -n selector target) through internal block parameters. There is no
      # user-facing runtime variable: isolate a row by running its generated test by name, then break normally.

      def build_where_iterator(data_rows)
        s(:send,
          s(:send,
            s(:array, *data_rows.map { |row| build_where_data_row(row) }),
            :each,
           ),
          :with_index
         )
      end

      def build_where_data_row(row)
        children = row.dup
        children << s(:int, row.first&.loc&.expression&.line)
        anchor = row.first
        anchor&.loc&.expression ? s_at(anchor, :array, *children) : s(:array, *children)
      end

      def build_where_args(header)
        injected_args = header.map { |column| s(:arg, column) }
        injected_args << s(:arg, TestMethodDefTransformation::ROW_LINE_ARG)
        s(:args,
          s(:mlhs, *injected_args),
          s(:arg, TestMethodDefTransformation::ROW_INDEX_ARG),
         )
      end
    end
  end
end
