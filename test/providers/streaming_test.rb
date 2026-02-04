# frozen_string_literal: true

require 'test_helper'
class StreamingFallbackTest < Minitest::Test
  def test_stream_returns_enumerator
    api_key = ENV.fetch('ANTHROPIC_API_KEY', nil)
    model = ENV.fetch('ANTHROPIC_MODEL', 'claude-3-haiku-20240307')
    skip 'ANTHROPIC_API_KEY not set' unless api_key

    provider = Rubyrana::Providers::Anthropic.new(api_key: api_key, model: model)

    stream = provider.stream(prompt: 'Reply with the word: ok')
    assert_kind_of Enumerator, stream
    assert stream.to_a.join.downcase.include?('ok')
  end

  def test_stream_yields_with_block
    api_key = ENV.fetch('ANTHROPIC_API_KEY', nil)
    model = ENV.fetch('ANTHROPIC_MODEL', 'claude-3-haiku-20240307')
    skip 'ANTHROPIC_API_KEY not set' unless api_key

    provider = Rubyrana::Providers::Anthropic.new(api_key: api_key, model: model)

    chunks = []
    provider.stream(prompt: 'Reply with the word: ok') { |chunk| chunks << chunk }
    assert chunks.join.downcase.include?('ok')
  end
end
