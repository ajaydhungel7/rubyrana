# frozen_string_literal: true

module Rubyrana
  class Agent
    def initialize(model: nil, tools: [], load_tools_from: nil, memory: true, history: [], safety_filters: [], store: nil, session_id: nil)
      @model = model || Rubyrana.config.default_provider
      raise ConfigurationError, "No provider configured" unless @model

      @tool_registry = ToolRegistry.new(tools)
      @load_tools_from = load_tools_from
      @memory = memory
      @safety_filters = safety_filters
      @store = store
      @session_id = session_id
      @messages = history.dup
      load_tools_from_directory
      load_persisted_messages
    end

    def call(prompt, **opts)
      apply_safety_filters(prompt)
      messages = @memory ? @messages.dup : []
      messages << { role: "user", content: prompt }
      max_iterations = opts.delete(:max_iterations) || 5

      max_iterations.times do
        response = @model.complete(messages: messages, tools: @tool_registry.definitions, **opts)
        text = response[:text] || response["text"] || ""
        tool_calls = response[:tool_calls] || response["tool_calls"] || []
        assistant_content = response[:assistant_content] || response["assistant_content"]
        @last_usage = response[:usage] || response["usage"]

        if tool_calls.any?
          log_debug("Tool calls requested", tool_calls: tool_calls)
          if assistant_content
            messages << { role: "assistant", content: assistant_content }
          elsif !text.to_s.empty?
            messages << { role: "assistant", content: text }
          end

          tool_calls.each do |call|
            tool_name = call[:name] || call["name"]
            tool_call_id = call[:id] || call["id"]
            arguments = call[:arguments] || call["arguments"] || {}
            tool = @tool_registry.fetch(tool_name)
            raise ToolError, "Unknown tool: #{tool_name}" unless tool

            log_debug("Running tool", tool: tool_name, arguments: arguments)
            result = tool.call(**symbolize_keys(arguments))
            tool_message = { role: "tool", name: tool.name, content: result.to_s }
            tool_message[:tool_call_id] = tool_call_id if tool_call_id
            messages << tool_message
          end

          next
        end

        apply_safety_filters(text.to_s)
        messages << { role: "assistant", content: text.to_s }
        @messages = messages if @memory
        persist_messages
        return text.to_s
      end

      raise ToolError, "Tool loop exceeded max iterations"
    end

    def stream(prompt, **opts, &block)
      apply_safety_filters(prompt)
      messages = @memory ? @messages.dup : []
      messages << { role: "user", content: prompt }

      output = String.new
      stream_proc = lambda do |chunk|
        output << chunk.to_s
        block.call(chunk) if block
      end

      if block
        @model.stream(messages: messages, tools: @tool_registry.definitions, **opts, &stream_proc)
        apply_safety_filters(output)
        messages << { role: "assistant", content: output }
        @messages = messages if @memory
        persist_messages
        return
      end

      Enumerator.new do |yielder|
        @model.stream(messages: messages, tools: @tool_registry.definitions, **opts) do |chunk|
          output << chunk.to_s
          yielder << chunk.to_s
        end

        apply_safety_filters(output)
        messages << { role: "assistant", content: output }
        @messages = messages if @memory
        persist_messages
      end
    end

    def messages
      @messages.dup
    end

    def last_usage
      @last_usage
    end

    def reset!
      @messages.clear
      persist_messages
    end

    private

    def symbolize_keys(hash)
      hash.each_with_object({}) do |(key, value), acc|
        acc[key.to_sym] = value
      end
    end

    def log_debug(message, **data)
      return unless Rubyrana.config.debug

      Rubyrana.config.logger.debug({ message: message, **data })
    end

    def apply_safety_filters(text)
      value = text.to_s
      @safety_filters.each { |filter| filter.enforce!(value) }
    end

    def load_persisted_messages
      return unless @store && @session_id

      @messages = @store.load(@session_id)
    end

    def load_tools_from_directory
      return unless @load_tools_from

      loader = Rubyrana::Tools::Loader.new(@load_tools_from)
      loaded = loader.load
      loaded.each { |tool| @tool_registry.register(tool) }
    end

    def persist_messages
      return unless @store && @session_id

      @store.save(@session_id, @messages)
    end
  end
end
