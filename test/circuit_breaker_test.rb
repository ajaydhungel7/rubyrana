# frozen_string_literal: true

require "test_helper"

class CircuitBreakerTest < Minitest::Test
  def test_opens_after_failures
    breaker = Rubyrana::Retry::CircuitBreaker.new(failure_threshold: 2, reset_timeout: 0.01)

    assert breaker.allow_request?
    breaker.record_failure
    assert_equal :closed, breaker.state
    breaker.record_failure
    assert_equal :open, breaker.state
  end

  def test_half_open_after_timeout
    breaker = Rubyrana::Retry::CircuitBreaker.new(failure_threshold: 1, reset_timeout: 0.0)
    breaker.record_failure
    assert_equal :open, breaker.state

    assert breaker.allow_request?
    assert_equal :half_open, breaker.state
  end

  def test_closes_after_half_open_success
    breaker = Rubyrana::Retry::CircuitBreaker.new(failure_threshold: 1, reset_timeout: 0.0)
    breaker.record_failure
    breaker.allow_request?
    breaker.record_success

    assert_equal :closed, breaker.state
  end
end
