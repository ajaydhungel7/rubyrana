# frozen_string_literal: true

require "test_helper"
require "faraday"
require "json"

class AnthropicProviderTest < Minitest::Test
  def test_complete_returns_text
    body = {
      "content" => [{ "type" => "text", "text" => "hello" }],
      "usage" => { "input_tokens" => 1, "output_tokens" => 2 }
    }

    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/v1/messages") do
        [200, { "Content-Type" => "application/json" }, JSON.dump(body)]
      end
    end

    client = Faraday.new { |builder| builder.adapter :test, stubs }
    provider = Rubyrana::Providers::Anthropic.new(api_key: "test", model: "claude", client: client)

    result = provider.complete(prompt: "hi")
    assert_equal "hello", result[:text]
    assert_equal [], result[:tool_calls]
    assert_equal({ "input_tokens" => 1, "output_tokens" => 2 }, result[:usage])
    stubs.verify_stubbed_calls
  end

  def test_complete_parses_tool_calls
    body = {
      "content" => [
        { "type" => "tool_use", "name" => "word_count", "input" => { "text" => "hello" } }
      ]
    }

    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/v1/messages") do
        [200, { "Content-Type" => "application/json" }, JSON.dump(body)]
      end
    end

    client = Faraday.new { |builder| builder.adapter :test, stubs }
    provider = Rubyrana::Providers::Anthropic.new(api_key: "test", model: "claude", client: client)

    result = provider.complete(prompt: "hi")
    assert_equal 1, result[:tool_calls].size
    assert_equal "word_count", result[:tool_calls][0][:name]
    assert_equal({ "text" => "hello" }, result[:tool_calls][0][:arguments])
    stubs.verify_stubbed_calls
  end
end
