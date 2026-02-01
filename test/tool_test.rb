# frozen_string_literal: true

require "test_helper"

class ToolTest < Minitest::Test
  def test_tool_calls_block
    tool = Rubyrana::Tool.new("echo") { |text:| text }
    assert_equal "hi", tool.call(text: "hi")
  end

  def test_tool_to_h
    tool = Rubyrana::Tool.new("echo", description: "Echo", schema: { type: "object" }) { |text:| text }
    assert_equal "echo", tool.to_h[:name]
    assert_equal "Echo", tool.to_h[:description]
    assert_equal({ type: "object" }, tool.to_h[:input_schema])
  end
end
