# frozen_string_literal: true

require "test_helper"
require "json"
require "stringio"

class MCPClientTest < Minitest::Test
  def test_with_session_lists_tools_and_calls
    responses = [
      JSON.dump({ jsonrpc: "2.0", id: 1, result: {} }) + "\n",
      JSON.dump({ jsonrpc: "2.0", id: 2, result: { "tools" => [{ "name" => "echo", "description" => "Echo", "inputSchema" => { "type" => "object", "properties" => { "text" => { "type" => "string" } }, "required" => ["text"] } }] } }) + "\n",
      JSON.dump({ jsonrpc: "2.0", id: 3, result: { "content" => "ok" } }) + "\n"
    ]

    stdin = StringIO.new
    stdout = MCPTestIO::FakeStdout.new(responses)
    stderr = MCPTestIO::FakeStderr.new([])

    client = Rubyrana::MCP::Client.new(io: { stdin: stdin, stdout: stdout, stderr: stderr })

    tool_result = nil
    client.with_session do |tools|
      assert_equal 1, tools.length
      tool_result = tools.first.call(text: "hello")
    end

    assert_equal({ "content" => "ok" }, tool_result)

    stdin.rewind
    written = stdin.read
    assert_includes written, "\"method\":\"initialize\""
    assert_includes written, "\"method\":\"tools/list\""
    assert_includes written, "\"method\":\"tools/call\""
  end
end
