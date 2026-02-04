# frozen_string_literal: true

require "test_helper"
require "faraday"
require "json"

class AnthropicCircuitBreakerTest < Minitest::Test
  def test_circuit_breaker_opens
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/v1/messages") do
        [500, { "Content-Type" => "application/json" }, JSON.dump({ "error" => "fail" })]
      end
    end

    client = Faraday.new { |builder| builder.adapter :test, stubs }
    breaker = Rubyrana::Retry::CircuitBreaker.new(failure_threshold: 1, reset_timeout: 10.0)
    provider = Rubyrana::Providers::Anthropic.new(api_key: "test", model: "claude", client: client, circuit_breaker: breaker)

    assert_raises(Rubyrana::ProviderError) do
      provider.complete(prompt: "hi")
    end

    assert_equal :open, breaker.state
    stubs.verify_stubbed_calls
  end
end
