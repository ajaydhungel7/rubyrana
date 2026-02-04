# frozen_string_literal: true

module Rubyrana
  module Telemetry
    class Metrics
      def initialize(logger: nil, exporter: nil)
        @logger = logger
        @exporter = exporter
        @counters = Hash.new(0)
        @timings = Hash.new { |h, k| h[k] = [] }
      end

      def increment(name, value = 1, attributes = {})
        @counters[name] += value
        log(:increment, name, value, attributes)
        export(:counter, name, value, attributes)
      end

      def timing(name, value_ms, attributes = {})
        @timings[name] << value_ms
        log(:timing, name, value_ms, attributes)
        export(:timing, name, value_ms, attributes)
      end

      def counter(name)
        @counters[name]
      end

      def timings(name)
        @timings[name].dup
      end

      def snapshot
        {
          counters: @counters.dup,
          timings: @timings.transform_values(&:dup)
        }
      end

      def reset!
        @counters.clear
        @timings.clear
      end

      attr_writer :exporter

      private

      def log(type, name, value, attributes)
        return unless @logger

        @logger.debug({ type: type, name: name, value: value, attributes: attributes })
      end

      def export(kind, name, value, attributes)
        return unless @exporter

        @exporter.export({ type: 'metric', kind: kind, name: name, value: value, attributes: attributes })
      end
    end
  end
end
