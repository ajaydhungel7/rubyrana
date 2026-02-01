# frozen_string_literal: true

require "test_helper"

class ToolingTest < Minitest::Test
  def setup
    Rubyrana::Tooling.reset!
  end

  def test_tool_decorator_registers
    Rubyrana.tool("greet") { |name:| "hi #{name}" }
    assert_equal 1, Rubyrana::Tooling.tools.length
  end
end
