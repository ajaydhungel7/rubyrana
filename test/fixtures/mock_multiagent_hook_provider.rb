# frozen_string_literal: true

module Rubyrana
  module TestFixtures
    class MockMultiagentHookProvider
      attr_reader :events_received, :event_types

      def initialize(event_types = :all)
        @event_types = event_types
        @events_received = []
      end

      def event_types_received
        @events_received.map(&:first)
      end

      def events
        @events_received.dup
      end

      def before_node_call(context)
        record(:before_node_call, context)
      end

      def after_node_call(context)
        record(:after_node_call, context)
      end

      def after_multiagent_invocation(context)
        record(:after_multiagent_invocation, context)
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
