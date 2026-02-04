# frozen_string_literal: true

require "test_helper"
require_relative "fixtures/mocked_model_provider"

class HooksEventsTest < Minitest::Test
  def test_hook_events_emitted_for_call
    responses = [
      { text: "Hello" }
    ]
    provider = Rubyrana::TestFixtures::MockedModelProvider.new(responses)
    agent = Rubyrana::Agent.new(model: provider)

    events = []
    registry = Rubyrana.config.hooks
    registry.add_callback(Rubyrana::Hooks::Events::BeforeInvocationEvent) { |event| events << event }
    registry.add_callback(Rubyrana::Hooks::Events::AfterInvocationEvent) { |event| events << event }
    registry.add_callback(Rubyrana::Hooks::Events::BeforeModelCallEvent) { |event| events << event }
    registry.add_callback(Rubyrana::Hooks::Events::AfterModelCallEvent) { |event| events << event }
    registry.add_callback(Rubyrana::Hooks::Events::MessageAddedEvent) { |event| events << event }

    result = agent.call("Hi")

    assert_equal "Hello", result
    assert_equal 6, events.length
    assert_instance_of Rubyrana::Hooks::Events::BeforeInvocationEvent, events[0]
    assert_instance_of Rubyrana::Hooks::Events::MessageAddedEvent, events[1]
    assert_instance_of Rubyrana::Hooks::Events::BeforeModelCallEvent, events[2]
    assert_instance_of Rubyrana::Hooks::Events::AfterModelCallEvent, events[3]
    assert_instance_of Rubyrana::Hooks::Events::MessageAddedEvent, events[4]
    assert_instance_of Rubyrana::Hooks::Events::AfterInvocationEvent, events[5]
  end

  def test_hook_events_emitted_for_tool_call
    responses = [
      {
        text: "",
        tool_calls: [
          { name: "echo", arguments: { text: "hi" } }
        ]
      },
      { text: "Done" }
    ]
    provider = Rubyrana::TestFixtures::MockedModelProvider.new(responses)
    tool = Rubyrana::Tool.new("echo") { |text:| text }
    agent = Rubyrana::Agent.new(model: provider, tools: [tool])

    events = []
    registry = Rubyrana.config.hooks
    registry.add_callback(Rubyrana::Hooks::Events::BeforeToolCallEvent) { |event| events << event }
    registry.add_callback(Rubyrana::Hooks::Events::AfterToolCallEvent) { |event| events << event }

    result = agent.call("Hi")

    assert_equal "Done", result
    assert_equal 2, events.length
    assert_instance_of Rubyrana::Hooks::Events::BeforeToolCallEvent, events[0]
    assert_instance_of Rubyrana::Hooks::Events::AfterToolCallEvent, events[1]
  end
end
