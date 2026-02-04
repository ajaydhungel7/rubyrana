# frozen_string_literal: true

module Rubyrana
  module EventLoop
    module Runner
      module_function

      def run(agent:, prompt:, structured_output_schema: nil, **opts)
        events = []
        callback_ids = attach_callbacks(events)

        if structured_output_schema
          result = agent.structured_output(prompt, schema: structured_output_schema, **opts)
          events << StructuredOutputEvent.new(structured_output: result)
          stop = StopEvent.new(
            stop_reason: "structured_output",
            message: nil,
            usage: agent.last_usage,
            structured_output: result,
            interrupts: nil
          )
          detach_callbacks(callback_ids)
          return [events, stop]
        end

        begin
          result = agent.call(prompt, return_result: true, **opts)
          stop = StopEvent.new(
            stop_reason: result.stop_reason || "end_turn",
            message: result.message,
            usage: result.usage,
            structured_output: result.structured_output,
            interrupts: result.interrupts
          )
          [events, stop]
        rescue Rubyrana::SafetyError => e
          interrupt = Rubyrana::Types::Interrupt.new(reason: "guardrail_intervened", message: e.message)
          events << InterruptEvent.new(interrupt: interrupt, timestamp: Time.now)
          stop = StopEvent.new(
            stop_reason: "guardrail_intervened",
            message: nil,
            usage: agent.last_usage,
            structured_output: nil,
            interrupts: [interrupt]
          )
          [events, stop]
        ensure
          detach_callbacks(callback_ids)
        end
      end

      def stream(agent:, prompt:, structured_output_schema: nil, **opts)
        return enum_for(:stream, agent: agent, prompt: prompt, structured_output_schema: structured_output_schema, **opts) unless block_given?

        if structured_output_schema
          result = agent.structured_output(prompt, schema: structured_output_schema, **opts)
          yield StructuredOutputEvent.new(structured_output: result)
          yield StopEvent.new(
            stop_reason: "structured_output",
            message: nil,
            usage: agent.last_usage,
            structured_output: result,
            interrupts: nil
          )
          return
        end

        agent.stream(prompt, **opts) do |chunk|
          if chunk.is_a?(Rubyrana::Types::AgentResult)
            yield StopEvent.new(
              stop_reason: chunk.stop_reason || "end_turn",
              message: chunk.message,
              usage: chunk.usage,
              structured_output: chunk.structured_output,
              interrupts: chunk.interrupts
            )
          else
            yield TextDeltaEvent.new(text: chunk.to_s, timestamp: Time.now)
          end
        end
      end

      def attach_callbacks(events)
        registry = Rubyrana.config.hooks
        ids = []

        ids << [Rubyrana::Hooks::Events::BeforeModelCallEvent, registry.add_callback(Rubyrana::Hooks::Events::BeforeModelCallEvent) do |event|
          events << ModelCallEvent.new(messages: event.messages, tools: event.tools, timestamp: event.timestamp)
        end]

        ids << [Rubyrana::Hooks::Events::AfterModelCallEvent, registry.add_callback(Rubyrana::Hooks::Events::AfterModelCallEvent) do |event|
          events << ModelResponseEvent.new(response: event.response, timestamp: event.timestamp)
        end]

        ids << [Rubyrana::Hooks::Events::BeforeToolCallEvent, registry.add_callback(Rubyrana::Hooks::Events::BeforeToolCallEvent) do |event|
          tool_use = Rubyrana::Types::ToolUse.new(name: event.tool_name, arguments: event.arguments, tool_call_id: nil)
          events << ToolCallEvent.new(tool_use: tool_use, timestamp: event.timestamp)
        end]

        ids << [Rubyrana::Hooks::Events::AfterToolCallEvent, registry.add_callback(Rubyrana::Hooks::Events::AfterToolCallEvent) do |event|
          events << ToolResultEvent.new(tool_name: event.tool_name, result: event.result, timestamp: event.timestamp)
        end]

        ids << [Rubyrana::Hooks::Events::MessageAddedEvent, registry.add_callback(Rubyrana::Hooks::Events::MessageAddedEvent) do |event|
          events << MessageEvent.new(message: event.message, timestamp: event.timestamp)
        end]

        ids
      end

      def detach_callbacks(ids)
        registry = Rubyrana.config.hooks
        ids.each { |event_class, id| registry.remove_callback(event_class, id) }
      end
    end
  end
end
