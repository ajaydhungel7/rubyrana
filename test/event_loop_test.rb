# frozen_string_literal: true

require "test_helper"
require_relative "fixtures/mocked_model_provider"

class EventLoopTest < Minitest::Test
  def test_event_loop_returns_stop_event_for_call
    provider = Rubyrana::TestFixtures::MockedModelProvider.new([{ text: "Hello" }])
    agent = Rubyrana::Agent.new(model: provider)

    events, stop = agent.event_loop("Hi")

    refute_empty events
    assert_instance_of Rubyrana::EventLoop::StopEvent, stop
    assert_equal "end_turn", stop.stop_reason
    assert_equal "Hello", stop.message[:content]
  end

  def test_event_loop_returns_structured_output_event
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
      properties: { name: { type: "string" } },
      required: ["name"]
    }

    events, stop = agent.event_loop("Extract", structured_output_schema: schema)

    assert_equal 1, events.length
    assert_instance_of Rubyrana::EventLoop::StructuredOutputEvent, events[0]
    assert_equal({ "name" => "Jane" }, events[0].structured_output)
    assert_equal "structured_output", stop.stop_reason
  end
end
