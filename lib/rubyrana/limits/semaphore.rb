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
          while @counts[key] >= @limit
            @condition.wait(@mutex)
          end
          @counts[key] += 1
        end
      end

      def release(key)
        @mutex.synchronize do
          @counts[key] -= 1 if @counts[key] > 0
          @condition.signal
        end
      end
    end
  end
end
