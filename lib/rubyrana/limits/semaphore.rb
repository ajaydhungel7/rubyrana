# frozen_string_literal: true

module Rubyrana
  module Limits
    class Semaphore
      def initialize(limit:)
        @limit = limit
        @mutex = Mutex.new
        @condition = ConditionVariable.new
        @counts = Hash.new(0)
      end

      def acquire(key)
        @mutex.synchronize do
          @condition.wait(@mutex) while @counts[key] >= @limit
          @counts[key] += 1
        end
      end

      def release(key)
        @mutex.synchronize do
          @counts[key] -= 1 if @counts[key].positive?
          @condition.signal
        end
      end
    end
  end
end
