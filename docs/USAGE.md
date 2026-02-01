# Rubyrana Usage

## Quick Start

1) Install the gem:

- Add to your Gemfile:
  - gem "rubyrana"

2) Configure a provider:

- Set an environment variable (e.g., ANTHROPIC_API_KEY)
- Configure Rubyrana:
  - Rubyrana.configure { |c| c.default_provider = Rubyrana::Providers::Anthropic.new(...) }

3) Create an agent and call it:

- agent = Rubyrana::Agent.new
- agent.call("Hello")

## Tools

Define tools with a Ruby block and pass them to the agent:

- word_count = Rubyrana::Tool.new("word_count") { |text:| text.split.size }
- agent = Rubyrana::Agent.new(tools: [word_count])

### Built-in Tools

- code_interpreter: execute Ruby code in a temporary process
- web_search: Serper-backed web search (users must supply WEB_SEARCH_API_KEY)
- web_search_mcp: MCP-backed web search (users supply MCP server command/args)

Example:

- tools = [Rubyrana::Tools.code_interpreter, Rubyrana::Tools.web_search]
- agent = Rubyrana::Agent.new(tools: tools)

## Tool Decorators + Loader

Define tools anywhere using `Rubyrana.tool`:

- Rubyrana.tool("hello") { |name:| "Hello, #{name}!" }

Load tools from a directory:

- agent = Rubyrana::Agent.new(load_tools_from: "./tools")

## MCP (Experimental)

Use the MCP client to load tools:

- mcp = Rubyrana::MCP::Client.new(command: "uvx", args: ["awslabs.aws-documentation-mcp-server@latest"])
- mcp.with_session { |tools| Rubyrana::Agent.new(tools: tools).call("...") }
