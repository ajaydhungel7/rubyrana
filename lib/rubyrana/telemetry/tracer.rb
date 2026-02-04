# frozen_string_literal: true

module Rubyrana
  module Telemetry
    class Tracer
      Span = Struct.new(:name, :attributes, :duration_ms, keyword_init: true)

      def initialize(logger: nil, metrics: nil, exporter: nil)
        @logger = logger
        @metrics = metrics
        @exporter = exporter
        @spans = []
      end

      def start_span(name, attributes = {})
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        result = block_given? ? yield : nil
        duration_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000

        @spans << Span.new(name: name, attributes: attributes, duration_ms: duration_ms)
        @metrics&.timing("rubyrana.span.duration_ms", duration_ms, attributes.merge({ span: name }))
        @logger&.debug({ type: "span", name: name, duration_ms: duration_ms, attributes: attributes })
        @exporter&.export({ type: "span", name: name, duration_ms: duration_ms, attributes: attributes })

        result
      end

      def spans
        @spans.dup
      end

      def reset!
        @spans.clear
      end

      def exporter=(exporter)
        @exporter = exporter
      end
    end
  end
end
