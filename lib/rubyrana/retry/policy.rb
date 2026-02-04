# frozen_string_literal: true

module Rubyrana
  module Retry
    class RetryableError < StandardError; end

    class Policy
      attr_reader :max_retries, :base_delay, :max_delay, :jitter

      def initialize(max_retries: 2, base_delay: 0.25, max_delay: 2.0, jitter: 0.1)
        @max_retries = max_retries
        @base_delay = base_delay
        @max_delay = max_delay
        @jitter = jitter
      end

      def run
        attempts = 0
        begin
          attempts += 1
          yield
        rescue RetryableError, Faraday::Error => e
          raise e if attempts > max_retries

          sleep(backoff(attempts))
          retry
        end
      end

      private

      def backoff(attempt)
        base = [@base_delay * (2**(attempt - 1)), @max_delay].min
        jitter_amount = base * @jitter * rand
        base + jitter_amount
      end
    end
  end
end
