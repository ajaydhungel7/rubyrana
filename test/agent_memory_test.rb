# frozen_string_literal: true

require 'test_helper'

class AgentMemoryTest < Minitest::Test
  def test_memory_accumulates_messages
    api_key = ENV.fetch('ANTHROPIC_API_KEY', nil)
    model = ENV.fetch('ANTHROPIC_MODEL', 'claude-3-haiku-20240307')
    skip 'ANTHROPIC_API_KEY not set' unless api_key

    provider = Rubyrana::Providers::Anthropic.new(api_key: api_key, model: model)
    agent = Rubyrana::Agent.new(model: provider)

    agent.call('hi')
    agent.call('there')

    messages = agent.messages
    assert_equal 4, messages.length
    assert_equal 'user', messages[0][:role]
    assert_equal 'assistant', messages[1][:role]
    assert_equal 'user', messages[2][:role]
    assert_equal 'assistant', messages[3][:role]
  end

  def test_reset_clears_memory
    api_key = ENV.fetch('ANTHROPIC_API_KEY', nil)
    model = ENV.fetch('ANTHROPIC_MODEL', 'claude-3-haiku-20240307')
    skip 'ANTHROPIC_API_KEY not set' unless api_key

    provider = Rubyrana::Providers::Anthropic.new(api_key: api_key, model: model)
    agent = Rubyrana::Agent.new(model: provider)

    agent.call('hi')
    agent.reset!

    assert_equal [], agent.messages
  end

  def test_memory_disabled
    api_key = ENV.fetch('ANTHROPIC_API_KEY', nil)
    model = ENV.fetch('ANTHROPIC_MODEL', 'claude-3-haiku-20240307')
    skip 'ANTHROPIC_API_KEY not set' unless api_key

    provider = Rubyrana::Providers::Anthropic.new(api_key: api_key, model: model)
    agent = Rubyrana::Agent.new(model: provider, memory: false)

    agent.call('hi')
    agent.call('there')

    assert_equal [], agent.messages
  end
end
