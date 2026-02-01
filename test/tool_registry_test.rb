# frozen_string_literal: true

require "test_helper"

class ToolRegistryTest < Minitest::Test
  def test_register_and_fetch
    registry = Rubyrana::ToolRegistry.new
    tool = Rubyrana::Tool.new("echo") { |text:| text }
    registry.register(tool)

    assert_equal tool, registry.fetch("echo")
  end

  def test_definitions
    tool = Rubyrana::Tool.new("echo", description: "Echo") { |text:| text }
    registry = Rubyrana::ToolRegistry.new([tool])

    assert_equal 1, registry.definitions.length
    assert_equal "echo", registry.definitions.first[:name]
  end
end
