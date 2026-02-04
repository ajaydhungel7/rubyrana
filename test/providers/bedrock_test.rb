# frozen_string_literal: true

require 'test_helper'
require 'json'
require 'stringio'

class BedrockProviderTest < Minitest::Test
  def test_bedrock_provider_disabled
    error = assert_raises(Rubyrana::ConfigurationError) do
      Rubyrana::Providers::Bedrock.new(client: Object.new, model_id: 'model')
    end

    assert_includes error.message, 'not included'
  end
end
