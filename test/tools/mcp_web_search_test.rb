# frozen_string_literal: true

require 'test_helper'
require 'json'

class MCPWebSearchTest < Minitest::Test
  def test_mcp_web_search_uses_tool
    responses = [
      "#{JSON.dump({ jsonrpc: '2.0', id: 1, result: {} })}\n",
      JSON.dump({ jsonrpc: '2.0', id: 2,
                  result: { 'tools' => [{ 'name' => 'web_search', 'description' => 'Search', 'inputSchema' => { 'type' => 'object', 'properties' => { 'query' => { 'type' => 'string' } }, 'required' => ['query'] } }] } }) + "\n",
      "#{JSON.dump({ jsonrpc: '2.0', id: 3, result: { 'results' => [] } })}\n"
    ]

    stdin = StringIO.new
    stdout = MCPTestIO::FakeStdout.new(responses)
    stderr = MCPTestIO::FakeStderr.new([])

    client = Rubyrana::MCP::Client.new(io: { stdin: stdin, stdout: stdout, stderr: stderr })
    tool = Rubyrana::Tools::MCPWebSearch.new(command: 'noop', args: []).tool

    Rubyrana::MCP::Client.stub(:new, client) do
      result = tool.call(query: 'ruby', limit: 1)
      assert_equal({ 'results' => [] }, result)
    end
  end
end
