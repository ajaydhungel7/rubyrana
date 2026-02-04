# frozen_string_literal: true

module Rubyrana
  module Limits
    class RateLimiter
      def initialize(rate_per_second:, burst: nil)
        @rate = rate_per_second.to_f
        @burst = burst ? burst.to_f : @rate
        @tokens = @burst
        @last_refill = Time.now
      end

      def acquire(count = 1)
        refill
        return if @tokens >= count

        sleep_time = ((count - @tokens) / @rate).clamp(0.0, 10.0)
        sleep(sleep_time) if sleep_time.positive?
        refill
        @tokens -= count if @tokens >= count
      end

      private

      def refill
        now = Time.now
        elapsed = now - @last_refill
        return if elapsed <= 0

        @tokens = [@burst, @tokens + (elapsed * @rate)].min
        @last_refill = now
      end
    end
  end
end
