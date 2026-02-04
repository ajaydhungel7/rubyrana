# frozen_string_literal: true

require "dotenv/load"
require "rubyrana"

mcp = Rubyrana::MCP::Client.new(
  command: "uvx",
  args: ["awslabs.aws-documentation-mcp-server@latest"]
)

mcp.with_session do |tools|
  Rubyrana.configure do |config|
    config.debug = true
    config.default_provider = Rubyrana::Providers::Anthropic.new(
      api_key: ENV.fetch("ANTHROPIC_API_KEY"),
      model: ENV.fetch("ANTHROPIC_MODEL", "claude-3-haiku-20240307")
    )
  end

  agent = Rubyrana::Agent.new(tools: tools)
  puts agent.call("What is Amazon Bedrock?")
end
