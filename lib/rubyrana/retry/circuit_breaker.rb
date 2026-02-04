# frozen_string_literal: true

module Rubyrana
  module Retry
    class CircuitBreaker
      attr_reader :state

      def initialize(failure_threshold: 3, reset_timeout: 5.0, half_open_success_threshold: 1)
        @failure_threshold = failure_threshold
        @reset_timeout = reset_timeout
        @half_open_success_threshold = half_open_success_threshold
        @failures = 0
        @half_open_successes = 0
        @state = :closed
        @opened_at = nil
      end

      def allow_request?
        return true if @state == :closed
        return half_open! if @state == :open && elapsed_since_open >= @reset_timeout

        @state == :half_open
      end

      def record_success
        if @state == :half_open
          @half_open_successes += 1
          close! if @half_open_successes >= @half_open_success_threshold
        else
          @failures = 0
        end
      end

      def record_failure
        if @state == :half_open
          open!
          return
        end

        @failures += 1
        open! if @failures >= @failure_threshold
      end

      private

      def open!
        @state = :open
        @opened_at = Time.now
        @failures = 0
        @half_open_successes = 0
      end

      def close!
        @state = :closed
        @opened_at = nil
        @failures = 0
        @half_open_successes = 0
      end

      def half_open!
        @state = :half_open
        @half_open_successes = 0
        true
      end

      def elapsed_since_open
        return 0 unless @opened_at

        Time.now - @opened_at
      end
    end
  end
end
