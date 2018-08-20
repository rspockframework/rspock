# RSpock

RSpock is a testing and specification framework built on top of Minitest. It intends to bring productivity back in the hands of developers with its incredibly simple yet highly expressive specification language.

Note: RSpock is heavily inspired by Spock for the Groovy programming language.

## Goals

* High readability, expressiveness, maintainability and productivity: Take back your very precious developer time!
* Encourage code reuse through expressive data-driven tests

## Features

* BDD-style code blocks: Given, When, Then, Cleanup, Where
* Data-driven testing with incredibly expressive table-based Where blocks
* Expressive assertions: Use familiar comparison operators `==` and `!=` for assertions!
* (Planned) BDD-style custom reporter that outputs information from Given, When, Then and Cleanup blocks
* (Planned) RSpock syntax pre-processor
* (Planned) Capture all Then block violations
* (Planned) Interaction-based testing, i.e. `1 * object.receive("message")` in Then blocks

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rspock'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rspock

### Rails

If you are using Rails, it is necessary to add a filter to *Rails.backtrace_cleaner* for source mapping to work, so that you get proper line numbers in Minitest backtraces. For your convenience, we've built a Rails Generator just for that:

    $ rails g rspock:install

## Usage

Getting started using RSpock is extremely easy!

```ruby
require 'rspock'

MyTest = Class.new(Minitest::Test) do
  include RSpock; break

  # Feature Methods go here
end
```

Note: The dynamic `Class.new` is required and the `break` in `include RSpock; break` is strongly recommended. See [here](###Runtime-RSpock-Syntax-Evaluation) to know more.

### Feature Methods

```ruby
test "adding 1 and 2 results in 3" do
  # Code Blocks go here
end
```

A feature method consists of four main conceptual phases:
- Setup
- Provide a stimulus to the system under test
- Describe the response expected from the system
- Cleanup

The first and last steps are optional, however the stimulus and response phases are always present.

### Code Blocks

| Blocks  | Phases   |
| ------- | -------- |
| Given   | Setup    |
| When    | Stimulus |
| Then    | Response |
| Cleanup | Cleanup  |
| Where   | Repeat   |

RSpock has support for each conceptual phase of a feature method. As such, feature methods are structured into Code Blocks, each representing a phase.

See below diagram for how you may arrange code blocks. Any directed path from Start to End is valid.

![](https://github.com/jpduchesne/rspock/raw/master/block_graph.png "Block Graph")

#### Given Block

```ruby
Given "An empty Cart and a Product"
cart = Cart.new
product = Product.new
```

The Given block is where you do any special setup for the Feature Method. It otherwise doesn't have any special semantics.

#### When Block

```ruby
When "Adding a product"
cart.add_product(Product.new)
```

The When block describes the stimulus to be applied to the system under test. It is always followed by a Then block.

#### Then Block

```ruby
Then "The product is added to the cart"
cart.products.size == 1
cart.products.first == product
```

The Then block describes the response from the stimulus. Any comparison done in the Then block is transformed to assert_equal / refute_equal under the hood. By convention, the LHS operand is considered the actual value, while the RHS operand is considered the expected value.

#### Cleanup Block

```ruby
Given "Open the file"
file = File.new("/invalid/file/path") # raises

# other blocks...

Cleanup
file&.close # Use safe navigation operator, since +file+ is nil if an error occurred.
```

The Cleanup block is where you free any resources used by a Feature Method. It runs even if a previous part of the Feature Method produced an exception. This means that Cleanup blocks must be coded defensively so as to not raise `NoMethodError`. A good way to do this in Ruby is demonstrated above by using the `&.` safe navigation operator.

#### Where Block

Where blocks have very special semantics in RSpock. They take the form of a data table, for readability.

Take a look at the following Feature Method for an example of how to use it:

```ruby
test "Adding #{a} and #{b} results in #{c}" do
  When "Adding two numbers"
  actual = a + b

  Then "We get the expected result"
  actual == c

  Where
  a  | b  | c
  -1 | -1 | -2
  -1 | 0  | -1
  0  | -1 | -1
  0  | 0  | 0
  0  | 1  | 1
  1  | 0  | 1
  1  | 1  | 2
```

The first row in the Where block is considered the Header. The names of columns will expose a local variable of the same name in the scope of the Feature Method. The header column names have the same constraints as method names in Ruby. Each other row defines one test case that will be generated, binding each column's data to the appropriate variable.

This effectively creates one version of the Feature Method for each data row. Note how we've listed test cases as if this was a truth table, ordering them by boolean increment. This makes it very easy to ensure all cases have been covered.

Note: Although the Where block is declared last, it is evaluated first. This means that it cannot variables previously defined in the test method. It is evaluated in Class scope, so it is possible to use generators or methods for column values, provided it is defined in class scope, not instance.

##### Test Name Interpolation

You might have noticed above that the test name contains interpolations, that's one of the features of RSpock! You can interpolate test names and use Where block header variables to parameterize the test name using the test data.

## More info

### Runtime RSPock Syntax Evaluation

```ruby
MyTest = Class.new(Minitest::Test) do
  include RSpock; break
end
```

RSpock, although having valid Ruby syntax, has different semantics in certain contexts, so that we can offer a more expressive and readable syntax. As such, we perform AST transformations on the code to produce semantically valid-in-context Ruby code.

Right now, the only supported RSpock syntax processing is runtime, so the reason why we use a dynamic `Class.new` to define the test class is to support runtime RSpock syntax evaluation. This combined with the `break` in `include RSpock; break` allows us to process the RSpock test class at runtime, and breaking out of the ruby block to avoid executing any further code, since we care about executing the processed code only.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rspock. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RSpock project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/rspock/blob/master/CODE_OF_CONDUCT.md).
