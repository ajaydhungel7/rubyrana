# frozen_string_literal: true

require "json"

module Rubyrana
  module Persistence
    class RedisStore < Base
      def initialize(redis:, namespace: "rubyrana")
        @redis = redis
        @namespace = namespace
      end

      def load(session_id)
        raw = @redis.get(key(session_id))
        return [] unless raw

        JSON.parse(raw)
      rescue StandardError => e
        raise Rubyrana::PersistenceError, e.message
      end

      def save(session_id, messages)
        @redis.set(key(session_id), JSON.dump(messages))
        true
      rescue StandardError => e
        raise Rubyrana::PersistenceError, e.message
      end

      private

      def key(session_id)
        "#{@namespace}:#{session_id}"
      end
    end
  end
end
