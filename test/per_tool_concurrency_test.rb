# frozen_string_literal: true

require "test_helper"
require_relative "fixtures/mocked_model_provider"

class PerToolConcurrencyTest < Minitest::Test
  class FakeSemaphore
    attr_reader :acquired, :released

    def initialize
      @acquired = []
      @released = []
    end

    def acquire(key)
      @acquired << key
    end

    def release(key)
      @released << key
    end
  end

  def test_per_tool_semaphore_used
    responses = [
      { text: "", tool_calls: [{ name: "echo", arguments: { text: "hi" } }] },
      { text: "Done" }
    ]
    provider = Rubyrana::TestFixtures::MockedModelProvider.new(responses)
    tool = Rubyrana::Tool.new("echo") { |text:| text }
    agent = Rubyrana::Agent.new(model: provider, tools: [tool])

    semaphore = FakeSemaphore.new
    Rubyrana.config.tool_semaphores_by_tool = { "echo" => semaphore }

    result = agent.call("Hi")

    assert_equal "Done", result
    assert_equal ["echo"], semaphore.acquired
    assert_equal ["echo"], semaphore.released
  ensure
    Rubyrana.config.tool_semaphores_by_tool = {}
  end
end
