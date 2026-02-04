# frozen_string_literal: true

module Rubyrana
  module TestFixtures
    class MockAgentTool
      attr_reader :name

      def initialize(name)
        @name = name.to_s
      end

      def description
        "Mock tool"
      end

      def schema
        { type: "object", properties: {}, required: [] }
      end

      def call(**_kwargs)
        "Mock result for #{@name}"
      end

      def to_h
        {
          name: @name,
          description: description,
          input_schema: schema
        }
      end
    end
  end
end
