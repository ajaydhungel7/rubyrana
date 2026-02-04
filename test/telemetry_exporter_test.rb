# frozen_string_literal: true

require "test_helper"
require "json"
require "tmpdir"

class TelemetryExporterTest < Minitest::Test
  def test_jsonl_exporter_writes_metrics_and_spans
    Dir.mktmpdir do |dir|
      path = File.join(dir, "telemetry.jsonl")
      exporter = Rubyrana::Telemetry::JsonlExporter.new(path: path)

      Rubyrana.config.metrics_exporter = exporter
      Rubyrana.config.trace_exporter = exporter

      Rubyrana.config.metrics.increment("metric.count", 1, { tag: "a" })
      Rubyrana.config.tracer.start_span("span.test", { tag: "b" }) {}

      lines = File.read(path).split("\n")
      assert_operator lines.length, :>=, 2

      payloads = lines.map { |line| JSON.parse(line) }
      types = payloads.map { |payload| payload["type"] }
      assert_includes types, "metric"
      assert_includes types, "span"
    end

    Rubyrana.config.metrics_exporter = nil
    Rubyrana.config.trace_exporter = nil
  end
end
