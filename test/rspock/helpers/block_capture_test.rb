# frozen_string_literal: true

require "test_helper"
require "rspock/helpers/block_capture"

class RealCollaborator
  def frame(title, &block)
    block.call("from_real") if block
    "real_return"
  end
end

class BlockCaptureTest < Minitest::Test
  # --- Mock objects ---

  def test_mock_captures_exact_block
    m = mock
    m.expects(:frame).with("Build").once
    getter = RSpock::Helpers::BlockCapture.capture(m, :frame)

    my_block = Proc.new { "hello" }
    m.frame("Build", &my_block)

    assert_same my_block, getter.call
  end

  def test_mock_nil_when_no_block_passed
    m = mock
    m.expects(:frame).with("Build").once
    getter = RSpock::Helpers::BlockCapture.capture(m, :frame)

    m.frame("Build")

    assert_nil getter.call
  end

  def test_mock_does_not_capture_from_other_methods
    m = mock
    m.expects(:other_method).once
    getter = RSpock::Helpers::BlockCapture.capture(m, :frame)

    my_block = Proc.new { "hello" }
    m.other_method(&my_block)

    assert_nil getter.call
  end

  def test_mock_yields_still_works
    m = mock
    m.expects(:frame).with("Build").yields("yielded_arg")
    getter = RSpock::Helpers::BlockCapture.capture(m, :frame)

    received = nil
    my_block = Proc.new { |x| received = x }
    m.frame("Build", &my_block)

    assert_same my_block, getter.call
    assert_equal "yielded_arg", received
  end

  def test_mock_returns_still_works
    m = mock
    m.expects(:frame).with("Build").returns("mock_result")
    getter = RSpock::Helpers::BlockCapture.capture(m, :frame)

    my_block = Proc.new { }
    result = m.frame("Build", &my_block)

    assert_same my_block, getter.call
    assert_equal "mock_result", result
  end

  # --- Real objects ---

  def test_real_object_captures_exact_block
    obj = RealCollaborator.new
    obj.expects(:frame).with("Build").once
    getter = RSpock::Helpers::BlockCapture.capture(obj, :frame)

    my_block = Proc.new { |x| }
    obj.frame("Build", &my_block)

    assert_same my_block, getter.call
  end

  def test_real_object_nil_when_no_block_passed
    obj = RealCollaborator.new
    obj.expects(:frame).with("Build").once
    getter = RSpock::Helpers::BlockCapture.capture(obj, :frame)

    obj.frame("Build")

    assert_nil getter.call
  end

  def test_real_object_returns_still_works
    obj = RealCollaborator.new
    obj.expects(:frame).with("Build").returns("stubbed").once
    getter = RSpock::Helpers::BlockCapture.capture(obj, :frame)

    my_block = Proc.new { }
    result = obj.frame("Build", &my_block)

    assert_same my_block, getter.call
    assert_equal "stubbed", result
  end

  def test_real_object_with_stubs
    obj = RealCollaborator.new
    obj.stubs(:frame).returns("stubbed")
    getter = RSpock::Helpers::BlockCapture.capture(obj, :frame)

    my_block = Proc.new { }
    result = obj.frame("Build", &my_block)

    assert_same my_block, getter.call
    assert_equal "stubbed", result
  end
end
