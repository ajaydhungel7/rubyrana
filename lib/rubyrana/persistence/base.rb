# frozen_string_literal: true

module Rubyrana
  module Persistence
    class Base
      def load(_session_id)
        []
      end

      def save(_session_id, _messages)
        true
      end
    end
  end
end
