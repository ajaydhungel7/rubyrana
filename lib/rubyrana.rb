# frozen_string_literal: true

require "securerandom"

require_relative "rubyrana/version"
require_relative "rubyrana/errors"
require_relative "rubyrana/hooks/base"
require_relative "rubyrana/hooks/registry"
require_relative "rubyrana/hooks/events"
require_relative "rubyrana/hooks/provider"
require_relative "rubyrana/telemetry/tracer"
require_relative "rubyrana/telemetry/metrics"
require_relative "rubyrana/telemetry/exporter"
require_relative "rubyrana/telemetry/jsonl_exporter"
require_relative "rubyrana/retry/policy"
require_relative "rubyrana/retry/circuit_breaker"
require_relative "rubyrana/limits/rate_limiter"
require_relative "rubyrana/limits/semaphore"
require_relative "rubyrana/config"
require_relative "rubyrana/tool"
require_relative "rubyrana/tool_registry"
require_relative "rubyrana/tooling"
require_relative "rubyrana/agent"
require_relative "rubyrana/tools"
require_relative "rubyrana/memory/strategy"
require_relative "rubyrana/session/context"
require_relative "rubyrana/session/types"
require_relative "rubyrana/session/repository"
require_relative "rubyrana/types/message"
require_relative "rubyrana/types/tool_result"
require_relative "rubyrana/types/tool_use"
require_relative "rubyrana/types/interrupt"
require_relative "rubyrana/types/agent_result"
require_relative "rubyrana/session/file_repository"
require_relative "rubyrana/session/redis_repository"
require_relative "rubyrana/a2a/types"
require_relative "rubyrana/a2a/converters"
require_relative "rubyrana/a2a/client"
require_relative "rubyrana/a2a/agent"
require_relative "rubyrana/event_loop/events"
require_relative "rubyrana/event_loop/runner"
require_relative "rubyrana/multiagent/router"
require_relative "rubyrana/tools/structured_output/schema"
require_relative "rubyrana/tools/structured_output/tool"
require_relative "rubyrana/multi_agent"
require_relative "rubyrana/safety/filter"
require_relative "rubyrana/persistence/base"
require_relative "rubyrana/persistence/file_store"
require_relative "rubyrana/persistence/redis_store"
require_relative "rubyrana/routing/keyword_router"
require_relative "rubyrana/mcp/client"
require_relative "rubyrana/providers/base"
require_relative "rubyrana/providers/openai"
require_relative "rubyrana/providers/anthropic"
require_relative "rubyrana/providers/bedrock"

module Rubyrana
  class << self
    def configure
      yield(config)
    end

    def config
      @config ||= Rubyrana::Config.new
    end
  end
end
