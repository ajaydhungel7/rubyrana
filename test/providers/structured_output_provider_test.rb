# frozen_string_literal: true

require "test_helper"
require_relative "../fixtures/mocked_model_provider"

class StructuredOutputProviderTest < Minitest::Test
  def test_structured_output_returns_hash
    responses = [
      {
        text: "",
        tool_calls: [
          { name: "__structured_output__", arguments: { "name" => "Jane", "age" => 29 } }
        ]
      }
    ]
    provider = Rubyrana::TestFixtures::MockedModelProvider.new(responses)

    schema = {
      type: "object",
      properties: { name: { type: "string" }, age: { type: "integer" } },
      required: ["name", "age"]
    }

    result = provider.structured_output(prompt: "Extract", schema: schema)
    assert_equal({ "name" => "Jane", "age" => 29 }, result)
  end

  def test_structured_output_raises_when_missing
    responses = [{ text: "No tool" }]
    provider = Rubyrana::TestFixtures::MockedModelProvider.new(responses)

    schema = {
      type: "object",
      properties: { name: { type: "string" } },
      required: ["name"]
    }

    assert_raises(Rubyrana::StructuredOutputError) do
      provider.structured_output(prompt: "Extract", schema: schema)
    end
  end

  def test_structured_output_retries_when_missing_on_first_response
    responses = [
      { text: "No tool" },
      {
        text: "",
        tool_calls: [
          { name: "__structured_output__", arguments: { "name" => "Jane" } }
        ]
      }
    ]
    provider = Rubyrana::TestFixtures::MockedModelProvider.new(responses)

    schema = {
      type: "object",
      properties: { name: { type: "string" } },
      required: ["name"]
    }

    result = provider.structured_output(prompt: "Extract", schema: schema)
    assert_equal({ "name" => "Jane" }, result)
  end
end
