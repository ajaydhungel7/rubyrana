# Rubyrana Feasibility & Implementation Report

This report evaluates whether the README goal is buildable and outlines what is required to deliver it as a Ruby gem. The README is treated as the target product spec.

## Executive Summary

Yes, this is buildable. Rubyrana can be implemented as a Ruby gem with a small, composable core plus optional provider and MCP integrations. The main complexity is in provider adapters and streaming/MCP support. A staged build plan can deliver a usable v0.1 quickly, then layer advanced features.

## Target Capabilities (from README)

1. **Simple agent loop** with clean Ruby API
2. **Anthropic-only** model support
3. **Tools system** with a Ruby DSL and directory hot-reload
4. **Streaming** support
5. **MCP support** via external servers

## What We Need to Build

### 1) Core Gem Structure
**Deliverables**
- Gem skeleton (gemspec, lib/ directory, versioning)
- `Rubyrana::Agent` API
- `Rubyrana::Tool` and tool registry
- Logging + configuration

**Suggested File Structure**
```
lib/
  rubyrana.rb
  rubyrana/version.rb
  rubyrana/agent.rb
  rubyrana/tool.rb
  rubyrana/tool_registry.rb
  rubyrana/config.rb
  rubyrana/errors.rb
  rubyrana/serialization.rb
  rubyrana/streaming/
  rubyrana/providers/
  rubyrana/mcp/
```

### 2) Agent Loop
**Core responsibilities**
- Accept a prompt and optional conversation history
- Call selected model provider
- Parse tool calls, invoke tools, and return a final response
- Provide a streaming mode

**What to implement**
- `Rubyrana::Agent#call(prompt, **opts)`
- `Rubyrana::Agent#stream(prompt, **opts)`
- Minimal memory: request + response history

### 3) Tooling System
**Requirements**
- A Ruby DSL to define tools
- Type/shape for tool inputs
- Tool invocation engine

**Implementation notes**
- Use `Rubyrana::Tool.new(name, description: ..., schema: ...) { |**args| ... }`
- For schema validation: use JSON Schema or a simple Ruby contract system
- Tool registry in `Rubyrana::ToolRegistry`

**Hot Reloading**
- Watch a `./tools` directory and load tools
- Use `listen` gem for filesystem events

### 4) Model Provider
**Implementation**
- Provider base class: `Rubyrana::Provider::Base`
- `#complete(prompt, tools:, stream:)` interface

**Required adapter**
- Anthropic (HTTP API)

**Dependencies**
- `faraday` or `httpx` for HTTP

### 5) MCP Integration
**Goal**
- Connect to MCP servers via stdio or HTTP

**Implementation**
- Add `Rubyrana::MCP::Client` that manages MCP lifecycle
- Use `mcp` protocol JSON-RPC style
- Provide `list_tools` and convert MCP tool defs into `Rubyrana::Tool`

**Dependencies**
- If using stdio: spawn a process and read/write JSON
- Ruby JSON-RPC support (custom or existing gem)

### 6) Streaming
**Goal**
- Return tokens incrementally

**Implementation**
- Provider adapters must support streaming
- Agent exposes `#stream` returning an enumerator or block callback

### 7) Error Handling & Telemetry
**Deliverables**
- Standard error types
- Retriable failures
- Optional logging and tracing hooks

### 8) Tests & CI
**Required**
- Unit tests for agent, tools, providers
- Integration tests with mock HTTP
- CI workflow (GitHub Actions)

## Feasibility Notes

- **Core agent + tools**: straightforward; Ruby is well-suited for this.
- **Provider adapter**: ensure request/response formats and tool use are correct.
- **MCP**: feasible but requires careful process IO handling and tool conversion.
- **Streaming**: depends on provider support; implement per-provider streaming.

## Proposed Delivery Plan

### Phase 0 — Foundations (1–2 weeks)
- Gem skeleton
- Agent loop (non-streaming)
- Tool system
- Anthropic adapter
- Minimal README

### Phase 1 — Streaming & Hardening (2–3 weeks)
- Streaming interface
- Robust errors

### Phase 2 — MCP Integration (2–3 weeks)
- MCP client via stdio
- Tool conversion + lifecycle
- Examples

### Phase 3 — Production Readiness (ongoing)
- CI, tests, docs site
- Performance and retries

## Gaps to Resolve Before Implementation

1. **Exact API design** for tools and agent history
2. **Anthropic model selection**
3. **Streaming interface**: enumerator vs callback
4. **MCP client spec**: confirm protocol requirements
5. **Gem naming** and branding assets

## Recommendation

Proceed with an Anthropic-native SDK that mirrors the README and emphasizes tool use, streaming, and MCP.

---

If you want, I can now scaffold the gem, implement the Phase 0 core, and evolve the README to match the actual API as we build.
