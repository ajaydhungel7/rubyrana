# Rubyrana Book

A practical, end‑to‑end guide to the Rubyrana agent framework.

## Table of Contents

1. [Overview](#overview)
2. [Installation](#installation)
3. [Quick Start](#quick-start)
4. [Core Concepts](#core-concepts)
   - [Agents](#agents)
   - [Models / Providers](#models--providers)
   - [Messages](#messages)
   - [Tools](#tools)
   - [Memory](#memory)
   - [Safety Filters](#safety-filters)
   - [Event Loop](#event-loop)
   - [Hooks](#hooks)
   - [Telemetry](#telemetry)
   - [Sessions & Persistence](#sessions--persistence)
   - [Rate Limiting & Concurrency](#rate-limiting--concurrency)
   - [Structured Output](#structured-output)
   - [MCP](#mcp)
   - [Multi‑Agent](#multi-agent)
   - [A2A](#a2a)
5. [Configuration](#configuration)
6. [Testing](#testing)
7. [Operations](#operations)
8. [Troubleshooting](#troubleshooting)
9. [Glossary](#glossary)

---

## Overview

Rubyrana is a Ruby SDK for building production‑ready AI agents with a clean, composable architecture. It focuses on:

- **Provider abstraction** (Anthropic-first)
- **Tooling and structured output**
- **Hooks + telemetry** for observability
- **Session repositories** for persistence
- **Event loop runner** for streaming and parity with Strands
- **Rate limiting and concurrency controls**

### Design Goals

1. **Simple to start**: one provider, one agent, one prompt.
2. **Composable to grow**: tools, hooks, telemetry, and storage are opt‑in.
3. **Production‑ready**: concurrency limits, retries, circuit breakers, and timeouts are first‑class.
4. **Observable by default**: metrics and spans are emitted without extra instrumentation.

### Mental Model

Think of Rubyrana as a loop that:

1. Builds a message list
2. Calls a provider
3. Executes tools (if requested)
4. Records events, telemetry, and sessions
5. Returns a final response or stream of events

---

## Installation

Add to your Gemfile:

```ruby
bundle add rubyrana
```

Ruby requirement: **>= 3.4.0**

If you use Bundler, ensure your Bundler version matches the `BUNDLED WITH` value in Gemfile.lock.

---

## Quick Start

```ruby
require 'rubyrana'

Rubyrana.configure do |config|
  config.default_provider = Rubyrana::Providers::Anthropic.new(
    api_key: ENV.fetch('ANTHROPIC_API_KEY'),
    model: ENV.fetch('ANTHROPIC_MODEL', 'claude-3-haiku-20240307')
  )
end

agent = Rubyrana::Agent.new
puts agent.call('Write a haiku about Ruby')
```

### Tool‑enabled agent

```ruby
echo = Rubyrana::Tool.new('echo', description: 'Echo input') { |text:| text }

agent = Rubyrana::Agent.new(tools: [echo])
puts agent.call('Say hello using the tool')
```

### Streaming

```ruby
agent.stream('Stream a short response') do |chunk|
  print chunk
end
```

---

## Core Concepts

### Agents

`Rubyrana::Agent` is the central orchestration class. It manages:

- Prompt/message flow
- Tool calling and tool results
- Hooks and telemetry events
- Rate limiting and concurrency
- Streaming and structured output

Typical usage:

```ruby
agent = Rubyrana::Agent.new(
  model: Rubyrana.config.default_provider,
  tools: [Rubyrana::Tool.new('echo') { |text:| text }]
)

agent.call('Hi')
```

#### Agent lifecycle (high‑level)

1. Prepare messages and tools
2. Call the provider
3. Execute tool calls (if any)
4. Add tool results to messages
5. Repeat until completion or iteration limit

#### Return types

- `call` returns a string by default
- Use `return_result: true` to receive a richer `AgentResult`

### Models / Providers

Providers implement the model interface:

- `#complete`
- `#stream`
- Optional structured output helpers

Anthropic provider (default in this project):

```ruby
provider = Rubyrana::Providers::Anthropic.new(
  api_key: ENV.fetch('ANTHROPIC_API_KEY'),
  model: 'claude-3-haiku-20240307'
)
```

#### Provider contract

`#complete` returns either:

- A plain string, or
- A hash with `text` and optional `tool_calls`

#### Reliability controls

Providers support retry policies and circuit breakers. These are configurable via `Rubyrana.config` and provider initialization.

### Messages

Messages are plain hashes with role/content:

```ruby
{ role: 'user', content: 'Hello' }
{ role: 'assistant', content: 'Hi!' }
```

Agents can accept a prompt or a full message list.

Common roles:

- `user`
- `assistant`
- `tool`
- `system` (provider‑dependent)

### Tools

Tools are named callable functions exposed to the model.

```ruby
echo = Rubyrana::Tool.new('echo') { |text:| text }
agent = Rubyrana::Agent.new(tools: [echo])
```

Tool definitions include:

- `name`
- `description`
- `schema` (JSON schema‑like input definition)

Example with schema:

```ruby
calculator = Rubyrana::Tool.new(
  'add',
  description: 'Add two numbers',
  schema: {
    type: 'object',
    properties: {
      a: { type: 'number' },
      b: { type: 'number' }
    },
    required: %w[a b]
  }
) { |a:, b:| a + b }
```

Tool failures raise `Rubyrana::ToolError`.

### Memory

Memory strategies control how conversation history is stored and trimmed. The default strategy keeps all messages.

You can provide a custom memory strategy to prune messages or apply a window.

### Safety Filters

Safety filters can block unwanted inputs/outputs.

```ruby
filter = Rubyrana::Safety::BlocklistFilter.new(patterns: ['blocked'])
filter.enforce!('this is blocked') # raises Rubyrana::SafetyError
```

Attach filters to an agent to enforce them across prompts and tool results.

### Event Loop

The event loop produces structured events for streaming or tool interactions. It mirrors Strands style events.

Example:

```ruby
runner = Rubyrana::EventLoop::Runner.new
runner.run(agent: agent, prompt: 'Summarize this')
```

### Hooks

Hooks let you attach callbacks to specific lifecycle events:

- `BeforeModelCallEvent`
- `AfterModelCallEvent`
- `BeforeToolCallEvent`
- `AfterToolCallEvent`
- `MessageAddedEvent`

Use `Rubyrana::Hooks::Registry` to subscribe.

Example:

```ruby
registry = Rubyrana::Hooks::Registry.new
registry.add_callback(Rubyrana::Hooks::Events::BeforeToolCallEvent) do |event|
  puts "Calling tool: #{event.tool_name}"
end

Rubyrana.config.hooks = registry
```

### Telemetry

Telemetry includes:

- `Metrics` (counters, timings)
- `Tracer` (spans)
- Exporters (e.g., JSONL)

Example:

```ruby
exporter = Rubyrana::Telemetry::JsonlExporter.new(path: 'telemetry.jsonl')
Rubyrana.config.metrics_exporter = exporter
Rubyrana.config.trace_exporter = exporter
```

### Sessions & Persistence

Sessions can be stored via repositories:

- In‑memory
- File repository
- Redis repository

This allows multi‑turn continuity and stateful agent behavior.

Example:

```ruby
repo = Rubyrana::Session::FileRepository.new(directory: './.rubyrana_sessions')
agent = Rubyrana::Agent.new(session_repository: repo, session_id: 'demo')
```

### Rate Limiting & Concurrency

Controls include:

- Global concurrency semaphore
- Per‑tool concurrency
- Per‑model rate limiters
- Per‑tool rate limiters

Example:

```ruby
Rubyrana.configure do |config|
  config.global_concurrency = 4
  config.tool_concurrency_by_tool = { 'web_search' => 2 }
  config.tool_rate_limiters['web_search'] = Rubyrana::Limits::RateLimiter.new(limit: 5, interval_s: 60)
end
```

### Structured Output

Structured output forces the model to respond via a tool schema:

```ruby
schema = {
  type: 'object',
  properties: { title: { type: 'string' } },
  required: ['title']
}

agent = Rubyrana::Agent.new(structured_output_schema: schema)
result = agent.structured_output('Give me a product title')
```

If the model does not return structured output, `Rubyrana::StructuredOutputError` is raised.

### MCP

MCP enables external tool servers:

```ruby
client = Rubyrana::MCP::Client.new(
  command: 'uvx',
  args: ['awslabs.aws-documentation-mcp-server@latest']
)
```

Use MCP tools inside an agent:

```ruby
client.with_session do |tools|
  agent = Rubyrana::Agent.new(tools: tools)
  puts agent.call('Search AWS docs for S3 versioning')
end
```

### Multi‑Agent

Multi‑agent graph execution supports routing and node orchestration.

Example:

```ruby
router = Rubyrana::Multiagent::Router.new
chosen = router.route('Summarize this policy', agents: [agent_a, agent_b])
chosen.call('Summarize this policy')
```

### A2A

A2A provides an agent‑to‑agent interface for external agent cards and task execution.

Example:

```ruby
a2a = Rubyrana::A2A::Client.new(endpoint: 'https://example.com')
card = a2a.agent_card
```

---

## Configuration

Configuration is centralized:

```ruby
Rubyrana.configure do |config|
  config.default_provider = provider
  config.tool_timeout = 5
  config.global_concurrency = 4
  config.tool_concurrency_by_tool = { 'search' => 2 }
end
```

Common options:

- `default_provider`
- `tool_timeout`
- `retry_policy` and `circuit_breaker`
- `global_concurrency`, `tool_concurrency_by_tool`
- `tool_rate_limiters`, `model_rate_limiters`
- `metrics_exporter`, `trace_exporter`

---

## Testing

```bash
bundle exec ruby -Itest test/**/*_test.rb
```

Run RuboCop:

```bash
bundle exec rubocop
```

---

## Operations

- Use JSONL exporters for telemetry
- Use Redis repository for multi‑process storage
- Configure rate limits per model/tool
- Keep `BUNDLED WITH` aligned with your team’s Bundler version

---

## Troubleshooting

- Ensure Ruby >= 3.4.0
- Ensure Bundler matches Gemfile.lock `BUNDLED WITH`
- If tools fail, check `tool_timeout` and rate limits
- If streaming stalls, verify provider timeouts and network access

---

## Glossary

- **Agent**: Orchestrates prompts, tools, and responses
- **Provider**: Model backend implementation
- **Tool**: Named callable exposed to model
- **Hook**: Lifecycle callback
- **Telemetry**: Metrics and tracing
- **MCP**: Model Context Protocol for external tools
- **A2A**: Agent‑to‑Agent protocol
- **Structured Output**: Tool‑enforced response schema
