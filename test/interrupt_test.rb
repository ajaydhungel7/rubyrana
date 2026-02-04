# frozen_string_literal: true

require "test_helper"
require_relative "fixtures/mocked_model_provider"

class InterruptTest < Minitest::Test
  def test_agent_interrupt_returns_agent_result
    provider = Rubyrana::TestFixtures::MockedModelProvider.new([{ text: "Hello" }])
    agent = Rubyrana::Agent.new(model: provider)
    agent.interrupt!(reason: "user_cancel", message: "Stop")

    result = agent.call("Hi", return_result: true)

    assert_instance_of Rubyrana::Types::AgentResult, result
    assert_equal "interrupted", result.stop_reason
    assert_equal "user_cancel", result.interrupts.first.reason
  end
end
