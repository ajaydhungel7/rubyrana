# frozen_string_literal: true

require "test_helper"

class ToolSchemaValidationTest < Minitest::Test
  def test_missing_required_argument
    tool = Rubyrana::Tool.new("echo", schema: {
      type: "object",
      properties: { text: { type: "string" } },
      required: ["text"]
    }) { |text:| text }

    assert_raises(Rubyrana::ToolError) { tool.call }
  end
end
