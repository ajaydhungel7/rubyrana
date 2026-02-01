# frozen_string_literal: true

require "test_helper"

class AnthropicStreamTest < Minitest::Test
  def test_extract_stream_delta
    provider = Rubyrana::Providers::Anthropic.new(api_key: "test", model: "claude", client: nil)

    event = { "type" => "content_block_delta", "delta" => { "text" => "hi" } }
    assert_equal "hi", provider.send(:extract_stream_delta, event)
  end
end
