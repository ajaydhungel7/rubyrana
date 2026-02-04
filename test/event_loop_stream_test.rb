# frozen_string_literal: true

require "test_helper"
require_relative "fixtures/mocked_model_provider"

class EventLoopStreamTest < Minitest::Test
  def test_event_loop_stream_text_deltas
    responses = [{ text: "", chunks: ["He", "llo"] }]
    provider = Rubyrana::TestFixtures::MockedModelProvider.new(responses)
    agent = Rubyrana::Agent.new(model: provider)

    events = Rubyrana::EventLoop::Runner.stream(agent: agent, prompt: "Hi").to_a
    assert_instance_of Rubyrana::EventLoop::TextDeltaEvent, events[0]
    assert_equal "He", events[0].text
    assert_instance_of Rubyrana::EventLoop::TextDeltaEvent, events[1]
    assert_equal "llo", events[1].text
  end
end
