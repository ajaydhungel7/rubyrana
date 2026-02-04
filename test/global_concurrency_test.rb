# frozen_string_literal: true

require "test_helper"
require_relative "fixtures/mocked_model_provider"

class GlobalConcurrencyTest < Minitest::Test
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

  def test_global_semaphore_used_for_model_calls
    provider = Rubyrana::TestFixtures::MockedModelProvider.new([{ text: "Hello" }])
    agent = Rubyrana::Agent.new(model: provider)

    semaphore = FakeSemaphore.new
    Rubyrana.config.global_semaphore = semaphore

    agent.call("Hi")

    assert_equal [:model], semaphore.acquired
    assert_equal [:model], semaphore.released
  ensure
    Rubyrana.config.global_semaphore = nil
  end
end
