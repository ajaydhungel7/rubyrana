# frozen_string_literal: true

require_relative "tools/code_interpreter"
require_relative "tools/mcp_web_search"
require_relative "tools/loader"
require_relative "tools/web_search"

module Rubyrana
  module Tools
    def self.code_interpreter(timeout_s: CodeInterpreter::DEFAULT_TIMEOUT)
      CodeInterpreter.new(timeout_s: timeout_s).tool
    end

    def self.web_search(api_key: ENV["WEB_SEARCH_API_KEY"], provider: WebSearch::DEFAULT_PROVIDER)
      WebSearch.new(api_key: api_key, provider: provider).tool
    end

    def self.web_search_mcp(command:, args: [], tool_name: "web_search")
      MCPWebSearch.new(command: command, args: args, tool_name: tool_name).tool
    end
  end
end
