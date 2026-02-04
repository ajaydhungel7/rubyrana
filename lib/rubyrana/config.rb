# frozen_string_literal: true

require 'logger'

module Rubyrana
  class Config
    attr_accessor :logger,
                  :default_provider,
                  :debug,
                  :hooks,
                  :tracer,
                  :metrics,
                  :retry_policy,
                  :circuit_breaker,
                  :tool_timeout,
                  :rate_limiter,
                  :tool_semaphore,
                  :model_rate_limiters,
                  :global_semaphore,
                  :tool_rate_limiters,
                  :tool_semaphores_by_tool

    attr_reader :metrics_exporter,
                :trace_exporter,
                :tool_concurrency,
                :tool_concurrency_by_tool,
                :global_concurrency

    def initialize
      @logger = Logger.new($stdout)
      @default_provider = nil
      @debug = false
      @hooks = Rubyrana::Hooks::Registry.new
      @metrics_exporter = nil
      @trace_exporter = nil
      @retry_policy = Rubyrana::Retry::Policy.new
      @circuit_breaker = Rubyrana::Retry::CircuitBreaker.new
      @tool_timeout = nil
      @rate_limiter = nil
      @tool_concurrency = nil
      @tool_semaphore = nil
      @model_rate_limiters = {}
      @global_concurrency = nil
      @global_semaphore = nil
      @tool_rate_limiters = {}
      @tool_concurrency_by_tool = {}
      @tool_semaphores_by_tool = {}
      @metrics = Rubyrana::Telemetry::Metrics.new(logger: @logger, exporter: @metrics_exporter)
      @tracer = Rubyrana::Telemetry::Tracer.new(logger: @logger, metrics: @metrics, exporter: @trace_exporter)
    end

    def metrics_exporter=(exporter)
      @metrics_exporter = exporter
      @metrics.exporter = exporter
    end

    def trace_exporter=(exporter)
      @trace_exporter = exporter
      @tracer.exporter = exporter
    end

    def tool_concurrency=(value)
      @tool_concurrency = value
      @tool_semaphore = value ? Rubyrana::Limits::Semaphore.new(limit: value) : nil
    end

    def tool_concurrency_by_tool=(mapping)
      @tool_concurrency_by_tool = mapping || {}
      @tool_semaphores_by_tool = @tool_concurrency_by_tool.transform_values do |limit|
        Rubyrana::Limits::Semaphore.new(limit: limit)
      end
    end

    def global_concurrency=(value)
      @global_concurrency = value
      @global_semaphore = value ? Rubyrana::Limits::Semaphore.new(limit: value) : nil
    end
  end
end
