# frozen_string_literal: true

module Rubyrana
  module TestFixtures
    class MockHookProvider
      attr_reader :events_received, :event_types

      def initialize(event_types = :all)
        @event_types = event_types
        @events_received = []
      end

      def register_with(registry)
        registry.register(self)
      end

      def event_types_received
        @events_received.map(&:first)
      end

      def events
        @events_received.dup
      end

      def before_request(context)
        record(:before_request, context)
      end

      def after_request(context)
        record(:after_request, context)
      end

      def on_tool_call(context)
        record(:on_tool_call, context)
      end

      def on_tool_result(context)
        record(:on_tool_result, context)
      end

      private

      def record(type, payload)
        return unless accept?(type)

        @events_received << [type, payload]
      end

      def accept?(type)
        return true if @event_types == :all

        Array(@event_types).include?(type)
      end
    end
  end
end
