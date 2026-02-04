# frozen_string_literal: true

module Rubyrana
  module Session
    class Context
      attr_reader :id, :metadata

      def initialize(id: nil, metadata: {})
        @id = id
        @metadata = metadata
      end
    end
  end
end
