# frozen_string_literal: true

require "test_helper"
require_relative "fixtures/mocked_model_provider"

class RateLimiterTest < Minitest::Test
  class FakeLimiter
    attr_reader :calls

    def initialize
      @calls = 0
    end

    def acquire(_count = 1)
      @calls += 1
    end
  end

  def test_rate_limiter_invoked_for_call
    limiter = FakeLimiter.new
    provider = Rubyrana::TestFixtures::MockedModelProvider.new([{ text: "Hello" }])
    agent = Rubyrana::Agent.new(model: provider)

    agent.call("Hi", rate_limiter: limiter)

    assert_equal 1, limiter.calls
  end
end
