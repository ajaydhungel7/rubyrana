# frozen_string_literal: true

require_relative "rubyrana/version"
require_relative "rubyrana/errors"
require_relative "rubyrana/config"
require_relative "rubyrana/tool"
require_relative "rubyrana/tool_registry"
require_relative "rubyrana/tooling"
require_relative "rubyrana/agent"
require_relative "rubyrana/tools"
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
