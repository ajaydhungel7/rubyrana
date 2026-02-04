# frozen_string_literal: true

require "test_helper"
require "faraday"
require "json"

class AnthropicRetryTest < Minitest::Test
  def test_retries_on_retryable_status
    attempts = 0
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/v1/messages") do
        attempts += 1
        if attempts == 1
          [500, { "Content-Type" => "application/json" }, JSON.dump({ "error" => "fail" })]
        else
          [200, { "Content-Type" => "application/json" }, JSON.dump({ "content" => [{ "type" => "text", "text" => "ok" }] })]
        end
      end
    end

    client = Faraday.new { |builder| builder.adapter :test, stubs }
    retry_policy = Rubyrana::Retry::Policy.new(max_retries: 1, base_delay: 0.0, max_delay: 0.0, jitter: 0.0)
    provider = Rubyrana::Providers::Anthropic.new(api_key: "test", model: "claude", client: client, retry_policy: retry_policy)

    result = provider.complete(prompt: "hi")
    assert_equal "ok", result[:text]
    assert_equal 2, attempts
    stubs.verify_stubbed_calls
  end
end
