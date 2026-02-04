# frozen_string_literal: true

require 'test_helper'
require_relative 'fixtures/mocked_model_provider'

class ToolRateLimiterTest < Minitest::Test
  class FakeLimiter
    attr_reader :calls

    def initialize
      @calls = 0
    end

    def acquire(_count = 1)
      @calls += 1
    end
  end

  def test_tool_rate_limiter_used
    responses = [
      { text: '', tool_calls: [{ name: 'echo', arguments: { text: 'hi' } }] },
      { text: 'Done' }
    ]
    provider = Rubyrana::TestFixtures::MockedModelProvider.new(responses)
    tool = Rubyrana::Tool.new('echo') { |text:| text }
    agent = Rubyrana::Agent.new(model: provider, tools: [tool])

    limiter = FakeLimiter.new
    Rubyrana.config.tool_rate_limiters['echo'] = limiter

    result = agent.call('Hi')

    assert_equal 'Done', result
    assert_equal 1, limiter.calls
  ensure
    Rubyrana.config.tool_rate_limiters.delete('echo')
  end
end
