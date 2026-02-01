<div align="center">
  <div>
    <img src="https://placehold.co/80x80" alt="Rubyrana" width="80" height="80">
  </div>

  <h1>Rubyrana</h1>
  <h2>Build production-ready AI agents in Ruby with just a few lines of code.</h2>

  <div align="center">
    <img alt="Gem version" src="https://img.shields.io/gem/v/rubyrana" />
    <img alt="Ruby" src="https://img.shields.io/badge/ruby-%3E%3D%203.1-brightgreen" />
    <img alt="License" src="https://img.shields.io/badge/license-Apache%202.0-blue" />
  </div>

  <p>
    <a href="#quick-start">Quick Start</a>
    ◆ <a href="#features">Features</a>
    ◆ <a href="#tools">Tools</a>
    ◆ <a href="#model-providers">Model Providers</a>
    ◆ <a href="#mcp">MCP</a>
  </p>
</div>

Rubyrana is a lightweight, model-driven Ruby SDK for building AI agents. Start with a simple conversational assistant, then scale to multi-tool workflows and production deployments.

## Quick Start

```bash
# Install Rubyrana
bundle add rubyrana
```

```ruby
require "rubyrana"

Rubyrana.configure do |config|
  config.default_provider = Rubyrana::Providers::Anthropic.new(
    api_key: ENV.fetch("ANTHROPIC_API_KEY"),
    model: ENV.fetch("ANTHROPIC_MODEL", "claude-3-haiku-20240307")
  )
end

agent = Rubyrana::Agent.new
puts agent.call("What is the square root of 1764?")
```

> **Note:** Configure your Anthropic credentials before running.

## Features

- **Simple agent loop** with a clean Ruby API
- **Anthropic-first** provider integration with tool calling and streaming
- **Tooling-first design** for structured, safe function calls
- **Streaming-ready** architecture (planned)
- **MCP support** to connect thousands of tools (planned)

## Tools

Create tools with a Ruby DSL:

```ruby
require "rubyrana"

word_count = Rubyrana::Tool.new("word_count") do |text:|
  text.split.size
end

agent = Rubyrana::Agent.new(tools: [word_count])
puts agent.call("How many words are in this sentence?")
```

### Built-in Tools

Rubyrana ships with optional built-in tools:

```ruby
require "rubyrana"

tools = [
  Rubyrana::Tools.code_interpreter,
  Rubyrana::Tools.web_search
]

agent = Rubyrana::Agent.new(tools: tools)
puts agent.call("Search Ruby 3.3 release highlights and summarize.")
```

> **Note:** `web_search` requires users to bring their own `WEB_SEARCH_API_KEY` (Serper). `code_interpreter` runs code in a local process.

### Tool Decorators + Loader

Define tools with a simple Ruby decorator and load them from a directory:

```ruby
require "rubyrana"

Rubyrana.tool("hello", description: "Greet a user", schema: {
  type: "object",
  properties: { name: { type: "string" } },
  required: ["name"]
}) do |name:|
  "Hello, #{name}!"
end

agent = Rubyrana::Agent.new(load_tools_from: "./tools")
puts agent.call("Use the hello tool to greet Ajay")
```

### Web Search via MCP (Preferred)

If you want a Strands-style approach, delegate web search to an MCP server:

```ruby
require "rubyrana"

web_search = Rubyrana::Tools.web_search_mcp(
  command: "uvx",
  args: ["awslabs.aws-documentation-mcp-server@latest"],
  tool_name: "search_documentation"
)

agent = Rubyrana::Agent.new(tools: [web_search])
puts agent.call("Search Bedrock docs and summarize the key points.")
```

Hot-reload tools from a folder:

```ruby
agent = Rubyrana::Agent.new(load_tools_from: "./tools")
agent.call("Use any tools you find in the tools directory")
```

## MCP (Experimental)

Connect Model Context Protocol servers:

```ruby
require "rubyrana"

mcp = Rubyrana::MCP::Client.new(command: "uvx", args: ["awslabs.aws-documentation-mcp-server@latest"])

mcp.with_session do |tools|
  agent = Rubyrana::Agent.new(tools: tools)
  puts agent.call("Tell me about Amazon Bedrock and how to use it with Ruby")
end
```

## Model Provider

Rubyrana is Anthropic-native today.

Example:

```ruby
require "rubyrana"

model = Rubyrana::Providers::Anthropic.new(
  api_key: ENV.fetch("ANTHROPIC_API_KEY"),
  model: ENV.fetch("ANTHROPIC_MODEL", "claude-3-haiku-20240307")
)

agent = Rubyrana::Agent.new(model: model)
puts agent.call("Explain agentic workflows in simple terms")
```

## Documentation

- Getting Started
- Core Concepts
- Tools & MCP
- Production Deployment

## Contributing

Contributions are welcome. Please open issues and PRs with clear reproduction steps and context.

## License

Apache 2.0
