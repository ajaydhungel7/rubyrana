# frozen_string_literal: true

require 'test_helper'

class AnthropicRealTest < Minitest::Test
  def test_real_api_call
    api_key = ENV.fetch('ANTHROPIC_API_KEY', nil)
    model = ENV['ANTHROPIC_MODEL_REAL'] || 'claude-3-haiku-20240307'

    skip 'ANTHROPIC_API_KEY not set' unless api_key

    provider = Rubyrana::Providers::Anthropic.new(api_key: api_key, model: model)
    result = provider.complete(prompt: 'Reply with the single word: ok')

    assert_includes result[:text].downcase, 'ok'
  end
end
