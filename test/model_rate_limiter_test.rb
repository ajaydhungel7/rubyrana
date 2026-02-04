# frozen_string_literal: true

require 'test_helper'
require_relative 'fixtures/mocked_model_provider'

class ModelRateLimiterTest < Minitest::Test
  class FakeLimiter
    attr_reader :calls

    def initialize
      @calls = 0
    end

    def acquire(_count = 1)
      @calls += 1
    end
  end

  def test_model_rate_limiter_used
    limiter = FakeLimiter.new
    provider = Rubyrana::TestFixtures::MockedModelProvider.new([{ text: 'Hello' }])
    agent = Rubyrana::Agent.new(model: provider)

    Rubyrana.config.model_rate_limiters[provider.class.name] = limiter

    agent.call('Hi')

    assert_equal 1, limiter.calls
  ensure
    Rubyrana.config.model_rate_limiters.delete(provider.class.name)
  end
end
