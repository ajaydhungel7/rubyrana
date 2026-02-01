# frozen_string_literal: true

require "json"
require "open3"

module Rubyrana
  module MCP
    class Client
      def initialize(command: nil, args: [], io: nil)
        @command = command
        @args = args
        @io = io
        @id = 0
      end

      def with_session
        if @io
          use_io(@io)
          initialize_session
          tools = list_tools.map { |tool_def| tool_from_mcp(tool_def) }
          return yield tools
        end

        raise Rubyrana::ConfigurationError, "MCP command is required" unless @command

        Open3.popen3(@command, *@args) do |stdin, stdout, stderr, wait_thr|
          use_io({ stdin: stdin, stdout: stdout, stderr: stderr, wait_thr: wait_thr })

          initialize_session
          tools = list_tools.map { |tool_def| tool_from_mcp(tool_def) }
          yield tools
        ensure
          cleanup
        end
      end

      private

      def initialize_session
        send_request("initialize", {
          protocolVersion: "2024-11-05",
          capabilities: {},
          clientInfo: { name: "rubyrana", version: Rubyrana::VERSION }
        })
      end

      def list_tools
        response = send_request("tools/list", {})
        response.fetch("tools", [])
      end

      def call_tool(name, arguments)
        response = send_request("tools/call", {
          name: name,
          arguments: arguments
        })

        response
      end

      def tool_from_mcp(defn)
        Rubyrana::Tool.new(
          defn.fetch("name"),
          description: defn["description"],
          schema: defn["inputSchema"]
        ) do |**args|
          call_tool(defn.fetch("name"), args)
        end
      end

      def send_request(method, params)
        @id += 1
        request = {
          jsonrpc: "2.0",
          id: @id,
          method: method,
          params: params
        }

        @stdin.write(JSON.dump(request))
        @stdin.write("\n")
        @stdin.flush

        read_response(@id)
      end

      def read_response(request_id)
        loop do
          line = @stdout.gets
          raise Rubyrana::ProviderError, "MCP server closed" unless line

          response = JSON.parse(line)
          next unless response["id"] == request_id

          if response["error"]
            raise Rubyrana::ProviderError, response["error"].to_s
          end

          return response.fetch("result", {})
        end
      rescue JSON::ParserError
        raise Rubyrana::ProviderError, "Invalid MCP response"
      end

      def cleanup
        return unless @stdin

        @stdin.close unless @stdin.closed?
        @stdout.close unless @stdout.closed?
        @stderr.close unless @stderr.closed?
        @wait_thr.value if @wait_thr
      rescue StandardError
        # Ignore cleanup errors
      end

      def use_io(io)
        @stdin = io.fetch(:stdin)
        @stdout = io.fetch(:stdout)
        @stderr = io.fetch(:stderr)
        @wait_thr = io.fetch(:wait_thr, nil)
      end
    end
  end
end
