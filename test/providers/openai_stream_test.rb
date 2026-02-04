# frozen_string_literal: true

require 'test_helper'

class OpenAIStreamTest < Minitest::Test
  def test_openai_stream_disabled
    error = assert_raises(Rubyrana::ConfigurationError) do
      Rubyrana::Providers::OpenAI.new(api_key: 'test', model: 'gpt')
    end

    assert_includes error.message, 'not included'
  end
end
