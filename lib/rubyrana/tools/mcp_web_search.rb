# frozen_string_literal: true

module Rubyrana
  module Tools
    class MCPWebSearch
      def initialize(command:, args: [], tool_name: 'web_search')
        @command = command
        @args = args
        @tool_name = tool_name
      end

      def tool
        Rubyrana::Tool.new(
          'web_search',
          description: 'Web search via MCP server tool.',
          schema: {
            type: 'object',
            properties: {
              query: { type: 'string' },
              limit: { type: 'number' }
            },
            required: ['query']
          }
        ) do |query:, limit: 5|
          mcp = Rubyrana::MCP::Client.new(command: @command, args: @args)
          mcp.with_session do |tools|
            tool = tools.find { |t| t.name == @tool_name }
            raise Rubyrana::ToolError, "MCP tool not found: #{@tool_name}" unless tool

            tool.call(query: query, limit: limit)
          end
        end
      end
    end
  end
end
