# frozen_string_literal: true

require "test_helper"
require_relative "fixtures/mocked_model_provider"

class StructuredOutputTest < Minitest::Test
  def test_structured_output_returns_hash
    responses = [
      {
        text: "",
        tool_calls: [
          {
            name: "__structured_output__",
            arguments: { "name" => "Jane", "age" => 29 }
          }
        ]
      }
    ]
    provider = Rubyrana::TestFixtures::MockedModelProvider.new(responses)
    agent = Rubyrana::Agent.new(model: provider)

    schema = {
      type: "object",
      properties: {
        name: { type: "string" },
        age: { type: "integer" }
      },
      required: ["name", "age"]
    }

    result = agent.structured_output("Extract user", schema: schema)
    assert_equal({ "name" => "Jane", "age" => 29 }, result)
  end

  def test_structured_output_retries_when_missing_on_first_response
    responses = [
      { text: "No tool" },
      {
        text: "",
        tool_calls: [
          {
            name: "__structured_output__",
            arguments: { "name" => "Jane", "age" => 29 }
          }
        ]
      }
    ]
    provider = Rubyrana::TestFixtures::MockedModelProvider.new(responses)
    agent = Rubyrana::Agent.new(model: provider)

    schema = {
      type: "object",
      properties: {
        name: { type: "string" },
        age: { type: "integer" }
      },
      required: ["name", "age"]
    }

    result = agent.structured_output("Extract user", schema: schema)
    assert_equal({ "name" => "Jane", "age" => 29 }, result)
  end

  def test_call_with_structured_output_schema_returns_agent_result
    responses = [
      {
        text: "",
        tool_calls: [
          {
            name: "__structured_output__",
            arguments: { "name" => "Jane", "age" => 29 }
          }
        ]
      }
    ]
    provider = Rubyrana::TestFixtures::MockedModelProvider.new(responses)
    agent = Rubyrana::Agent.new(model: provider)

    schema = {
      type: "object",
      properties: {
        name: { type: "string" },
        age: { type: "integer" }
      },
      required: ["name", "age"]
    }

    result = agent.call("Extract user", structured_output_schema: schema)
    assert_instance_of Rubyrana::Types::AgentResult, result
    assert_equal({ "name" => "Jane", "age" => 29 }, result.structured_output)
  end

  def test_stream_with_structured_output_schema_returns_agent_result
    responses = [
      {
        text: "",
        tool_calls: [
          {
            name: "__structured_output__",
            arguments: { "title" => "Widget" }
          }
        ]
      }
    ]
    provider = Rubyrana::TestFixtures::MockedModelProvider.new(responses)
    agent = Rubyrana::Agent.new(model: provider)

    schema = {
      type: "object",
      properties: {
        title: { type: "string" }
      },
      required: ["title"]
    }

    result = agent.stream("Get product", structured_output_schema: schema).to_a.last
    assert_instance_of Rubyrana::Types::AgentResult, result
    assert_equal({ "title" => "Widget" }, result.structured_output)
  end

  def test_stream_with_structured_output_schema_yields_result
    responses = [
      {
        text: "",
        tool_calls: [
          {
            name: "__structured_output__",
            arguments: { "title" => "Widget" }
          }
        ]
      }
    ]
    provider = Rubyrana::TestFixtures::MockedModelProvider.new(responses)
    agent = Rubyrana::Agent.new(model: provider)

    schema = {
      type: "object",
      properties: {
        title: { type: "string" }
      },
      required: ["title"]
    }

    yielded = nil
    result = agent.stream("Get product", structured_output_schema: schema) { |event| yielded = event }
    assert_instance_of Rubyrana::Types::AgentResult, result
    assert_equal({ "title" => "Widget" }, result.structured_output)
    assert_equal result, yielded
  end

  def test_structured_output_uses_default_schema
    responses = [
      {
        text: "",
        tool_calls: [
          {
            name: "__structured_output__",
            arguments: { "title" => "Widget" }
          }
        ]
      }
    ]
    provider = Rubyrana::TestFixtures::MockedModelProvider.new(responses)
    schema = {
      type: "object",
      properties: {
        title: { type: "string" }
      },
      required: ["title"]
    }

    agent = Rubyrana::Agent.new(model: provider, structured_output_schema: schema)
    result = agent.structured_output("Get product")
    assert_equal({ "title" => "Widget" }, result)
  end

  def test_structured_output_raises_without_schema
    provider = Rubyrana::TestFixtures::MockedModelProvider.new([{ text: "" }])
    agent = Rubyrana::Agent.new(model: provider)

    assert_raises(Rubyrana::StructuredOutputError) do
      agent.structured_output("No schema")
    end
  end

  def test_structured_output_raises_when_missing_required_field
    responses = [
      {
        text: "",
        tool_calls: [
          {
            name: "__structured_output__",
            arguments: { "name" => "Jane" }
          }
        ]
      }
    ]
    provider = Rubyrana::TestFixtures::MockedModelProvider.new(responses)
    agent = Rubyrana::Agent.new(model: provider)

    schema = {
      type: "object",
      properties: {
        name: { type: "string" },
        age: { type: "integer" }
      },
      required: ["name", "age"]
    }

    assert_raises(Rubyrana::StructuredOutputError) do
      agent.structured_output("Extract user", schema: schema)
    end
  end

  def test_structured_output_raises_when_model_does_not_return_tool
    responses = [{ text: "No tool" }]
    provider = Rubyrana::TestFixtures::MockedModelProvider.new(responses)
    agent = Rubyrana::Agent.new(model: provider)

    schema = {
      type: "object",
      properties: {
        name: { type: "string" }
      },
      required: ["name"]
    }

    assert_raises(Rubyrana::StructuredOutputError) do
      agent.structured_output("Extract user", schema: schema)
    end
  end
end
