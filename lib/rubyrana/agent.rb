# frozen_string_literal: true

require 'timeout'

module Rubyrana
  class Agent
    def initialize(model: nil, tools: [], load_tools_from: nil, memory: true, history: [], safety_filters: [],
                   store: nil, session_id: nil, memory_strategy: nil, structured_output_schema: nil, session_repository: nil, agent_id: nil)
      @model = model || Rubyrana.config.default_provider
      raise ConfigurationError, 'No provider configured' unless @model

      @tool_registry = ToolRegistry.new(tools)
      @load_tools_from = load_tools_from
      @memory = memory
      @safety_filters = safety_filters
      @store = store
      @session_id = session_id
      @session_repository = session_repository
      @agent_id = agent_id || (session_repository ? SecureRandom.uuid : nil)
      @memory_strategy = memory_strategy
      @default_structured_output_schema = structured_output_schema
      @messages = history.dup
      load_tools_from_directory
      load_persisted_messages
      ensure_session_records
      load_session_history
      emit_hook_event(Rubyrana::Hooks::Events::AgentInitializedEvent.new(agent: self, timestamp: Time.now))
    end

    def call(prompt, **opts)
      structured_schema = opts.delete(:structured_output_schema) || @default_structured_output_schema
      structured_tool = structured_schema ? Rubyrana::Tools::StructuredOutput::Tool.new(structured_schema) : nil
      structured_result = nil
      return_result = opts.delete(:return_result) { false }
      tool_results = []
      tool_uses = []
      interrupts = []
      tool_timeout = opts.delete(:tool_timeout) || Rubyrana.config.tool_timeout
      rate_limiter = opts.delete(:rate_limiter) || model_rate_limiter || Rubyrana.config.rate_limiter
      tool_semaphore = Rubyrana.config.tool_semaphore
      tool_semaphores_by_tool = Rubyrana.config.tool_semaphores_by_tool
      global_semaphore = Rubyrana.config.global_semaphore
      tool_rate_limiters = Rubyrana.config.tool_rate_limiters

      request_id = SecureRandom.uuid
      if @interrupted
        interrupts << @interrupted
        result = Rubyrana::Types::AgentResult.new(
          text: nil,
          structured_output: nil,
          usage: nil,
          message: nil,
          stop_reason: 'interrupted',
          tool_results: tool_results,
          tool_uses: tool_uses,
          interrupts: interrupts
        )
        @interrupted = nil
        return return_result ? result : ''
      end
      ensure_session_records
      context = build_context(request_id: request_id, prompt: prompt)
      Rubyrana.config.hooks.before_request(context)
      emit_hook_event(Rubyrana::Hooks::Events::BeforeInvocationEvent.new(agent: self, request_id: request_id,
                                                                         prompt: prompt, timestamp: Time.now))

      apply_safety_filters(prompt)
      messages = @memory ? @messages.dup : []
      user_message = { role: 'user', content: prompt }
      messages << user_message
      emit_hook_event(Rubyrana::Hooks::Events::MessageAddedEvent.new(agent: self, request_id: request_id,
                                                                     message: user_message, timestamp: Time.now))
      persist_session_message(user_message)
      max_iterations = opts.delete(:max_iterations) || 5

      Rubyrana.config.tracer.start_span('rubyrana.agent.call', context) do
        max_iterations.times do
          start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          tools_definitions = @tool_registry.definitions
          if structured_tool
            tools_definitions += [structured_tool.to_h]
            opts[:tool_choice] ||= { type: 'tool', name: structured_tool.name }
          end
          emit_hook_event(Rubyrana::Hooks::Events::BeforeModelCallEvent.new(agent: self, request_id: request_id,
                                                                            messages: messages, tools: tools_definitions, timestamp: Time.now))

          begin
            rate_limiter&.acquire(1)
            global_semaphore&.acquire(:model)
            response = @model.complete(messages: messages, tools: tools_definitions, **opts)
            emit_hook_event(Rubyrana::Hooks::Events::AfterModelCallEvent.new(agent: self, request_id: request_id,
                                                                             response: response, timestamp: Time.now))
          ensure
            global_semaphore&.release(:model)
          end
          elapsed_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000
          Rubyrana.config.metrics.timing('rubyrana.model.latency_ms', elapsed_ms, { request_id: request_id })

          text = response[:text] || response['text'] || ''
          tool_calls = response[:tool_calls] || response['tool_calls'] || []
          assistant_content = response[:assistant_content] || response['assistant_content']
          @last_usage = response[:usage] || response['usage']

          if tool_calls.any?
            log_debug('Tool calls requested', tool_calls: tool_calls)
            if assistant_content
              assistant_message = { role: 'assistant', content: assistant_content }
              messages << assistant_message
              emit_hook_event(Rubyrana::Hooks::Events::MessageAddedEvent.new(agent: self, request_id: request_id,
                                                                             message: assistant_message, timestamp: Time.now))
              persist_session_message(assistant_message)
            elsif !text.to_s.empty?
              assistant_message = { role: 'assistant', content: text }
              messages << assistant_message
              emit_hook_event(Rubyrana::Hooks::Events::MessageAddedEvent.new(agent: self, request_id: request_id,
                                                                             message: assistant_message, timestamp: Time.now))
              persist_session_message(assistant_message)
            end

            tool_calls.each do |call|
              tool_name = call[:name] || call['name']
              tool_call_id = call[:id] || call['id']
              arguments = call[:arguments] || call['arguments'] || {}
              if structured_tool && tool_name == structured_tool.name
                structured_tool.validate!(arguments)
                structured_result = arguments
                next
              end
              tool = @tool_registry.fetch(tool_name)
              raise ToolError, "Unknown tool: #{tool_name}" unless tool

              tool_uses << Rubyrana::Types::ToolUse.new(name: tool_name, arguments: arguments,
                                                        tool_call_id: tool_call_id)

              tool_rate_limiters[tool_name]&.acquire(1)

              Rubyrana.config.hooks.on_tool_call({ request_id: request_id, tool: tool_name, arguments: arguments })
              emit_hook_event(Rubyrana::Hooks::Events::BeforeToolCallEvent.new(agent: self, request_id: request_id,
                                                                               tool_name: tool_name, arguments: arguments, timestamp: Time.now))
              Rubyrana.config.metrics.increment('rubyrana.tool.call', 1, { request_id: request_id, tool: tool_name })
              log_debug('Running tool', tool: tool_name, arguments: arguments)
              begin
                semaphore = tool_semaphores_by_tool[tool_name] || tool_semaphore
                semaphore&.acquire(tool_name)
                result = if tool_timeout
                           Timeout.timeout(tool_timeout) { tool.call(**symbolize_keys(arguments)) }
                         else
                           tool.call(**symbolize_keys(arguments))
                         end
              rescue Timeout::Error
                raise ToolError, "Tool '#{tool_name}' exceeded timeout of #{tool_timeout}s"
              ensure
                semaphore&.release(tool_name)
              end
              Rubyrana.config.hooks.on_tool_result({ request_id: request_id, tool: tool_name, result: result })
              emit_hook_event(Rubyrana::Hooks::Events::AfterToolCallEvent.new(agent: self, request_id: request_id,
                                                                              tool_name: tool_name, result: result, timestamp: Time.now))
              tool_results << Rubyrana::Types::ToolResult.new(text: result.to_s,
                                                              structured: result.is_a?(Hash) ? result : nil)
              tool_message = build_tool_message(tool, result, tool_call_id)
              tool_message[:tool_call_id] = tool_call_id if tool_call_id
              messages << tool_message
              emit_hook_event(Rubyrana::Hooks::Events::MessageAddedEvent.new(agent: self, request_id: request_id,
                                                                             message: tool_message, timestamp: Time.now))
              persist_session_message(tool_message)
            end

            if structured_result
              return Rubyrana::Types::AgentResult.new(
                text: text.to_s,
                structured_output: structured_result,
                usage: @last_usage,
                message: { role: 'assistant', content: text.to_s },
                stop_reason: 'structured_output',
                tool_results: tool_results,
                tool_uses: tool_uses,
                interrupts: interrupts
              )
            end
            next
          end

          apply_safety_filters(text.to_s)
          assistant_message = { role: 'assistant', content: text.to_s }
          messages << assistant_message
          emit_hook_event(Rubyrana::Hooks::Events::MessageAddedEvent.new(agent: self, request_id: request_id,
                                                                         message: assistant_message, timestamp: Time.now))
          persist_session_message(assistant_message)
          @messages = apply_memory_strategy(messages) if @memory
          persist_messages
          Rubyrana.config.hooks.after_request(context.merge({ response: text.to_s, usage: @last_usage }))
          emit_hook_event(Rubyrana::Hooks::Events::AfterInvocationEvent.new(agent: self, request_id: request_id,
                                                                            prompt: prompt, response: text.to_s, usage: @last_usage, timestamp: Time.now))
          if return_result || structured_result
            return Rubyrana::Types::AgentResult.new(
              text: text.to_s,
              structured_output: structured_result,
              usage: @last_usage,
              message: { role: 'assistant', content: text.to_s },
              stop_reason: structured_result ? 'structured_output' : 'end_turn',
              tool_results: tool_results,
              tool_uses: tool_uses,
              interrupts: interrupts
            )
          end
          return text.to_s
        end
      end

      raise ToolError, 'Tool loop exceeded max iterations'
    end

    def stream(prompt, **opts, &block)
      structured_schema = opts.delete(:structured_output_schema) || @default_structured_output_schema
      if structured_schema
        result = structured_output(prompt, schema: structured_schema, **opts)
        agent_result = Rubyrana::Types::AgentResult.new(text: nil, structured_output: result, usage: @last_usage,
                                                        stop_reason: 'structured_output')
        if block
          block.call(agent_result)
          return agent_result
        end

        return Enumerator.new do |yielder|
          yielder << agent_result
        end
      end

      request_id = SecureRandom.uuid
      ensure_session_records
      context = build_context(request_id: request_id, prompt: prompt)
      Rubyrana.config.hooks.before_request(context)
      emit_hook_event(Rubyrana::Hooks::Events::BeforeInvocationEvent.new(agent: self, request_id: request_id,
                                                                         prompt: prompt, timestamp: Time.now))

      apply_safety_filters(prompt)
      messages = @memory ? @messages.dup : []
      user_message = { role: 'user', content: prompt }
      messages << user_message
      emit_hook_event(Rubyrana::Hooks::Events::MessageAddedEvent.new(agent: self, request_id: request_id,
                                                                     message: user_message, timestamp: Time.now))
      persist_session_message(user_message)

      output = String.new
      stream_proc = lambda do |chunk|
        output << chunk.to_s
        block&.call(chunk)
      end

      rate_limiter = opts.delete(:rate_limiter) || model_rate_limiter || Rubyrana.config.rate_limiter
      global_semaphore = Rubyrana.config.global_semaphore

      if block
        Rubyrana.config.tracer.start_span('rubyrana.agent.stream', context) do
          start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          emit_hook_event(Rubyrana::Hooks::Events::BeforeModelCallEvent.new(agent: self, request_id: request_id,
                                                                            messages: messages, tools: @tool_registry.definitions, timestamp: Time.now))
          begin
            rate_limiter&.acquire(1)
            global_semaphore&.acquire(:model)
            @model.stream(messages: messages, tools: @tool_registry.definitions, **opts, &stream_proc)
            emit_hook_event(Rubyrana::Hooks::Events::AfterModelCallEvent.new(agent: self, request_id: request_id,
                                                                             response: { text: output }, timestamp: Time.now))
          ensure
            global_semaphore&.release(:model)
          end
          elapsed_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000
          Rubyrana.config.metrics.timing('rubyrana.model.latency_ms', elapsed_ms, { request_id: request_id })
        end
        apply_safety_filters(output)
        assistant_message = { role: 'assistant', content: output }
        messages << assistant_message
        emit_hook_event(Rubyrana::Hooks::Events::MessageAddedEvent.new(agent: self, request_id: request_id,
                                                                       message: assistant_message, timestamp: Time.now))
        persist_session_message(assistant_message)
        @messages = apply_memory_strategy(messages) if @memory
        persist_messages
        Rubyrana.config.hooks.after_request(context.merge({ response: output }))
        emit_hook_event(Rubyrana::Hooks::Events::AfterInvocationEvent.new(agent: self, request_id: request_id,
                                                                          prompt: prompt, response: output, usage: @last_usage, timestamp: Time.now))
        return
      end

      Enumerator.new do |yielder|
        Rubyrana.config.tracer.start_span('rubyrana.agent.stream', context) do
          start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          emit_hook_event(Rubyrana::Hooks::Events::BeforeModelCallEvent.new(agent: self, request_id: request_id,
                                                                            messages: messages, tools: @tool_registry.definitions, timestamp: Time.now))
          begin
            rate_limiter&.acquire(1)
            global_semaphore&.acquire(:model)
            @model.stream(messages: messages, tools: @tool_registry.definitions, **opts) do |chunk|
              output << chunk.to_s
              yielder << chunk.to_s
            end
            emit_hook_event(Rubyrana::Hooks::Events::AfterModelCallEvent.new(agent: self, request_id: request_id,
                                                                             response: { text: output }, timestamp: Time.now))
          ensure
            global_semaphore&.release(:model)
          end
          elapsed_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000
          Rubyrana.config.metrics.timing('rubyrana.model.latency_ms', elapsed_ms, { request_id: request_id })
        end

        apply_safety_filters(output)
        assistant_message = { role: 'assistant', content: output }
        messages << assistant_message
        emit_hook_event(Rubyrana::Hooks::Events::MessageAddedEvent.new(agent: self, request_id: request_id,
                                                                       message: assistant_message, timestamp: Time.now))
        persist_session_message(assistant_message)
        @messages = apply_memory_strategy(messages) if @memory
        persist_messages
        Rubyrana.config.hooks.after_request(context.merge({ response: output }))
        emit_hook_event(Rubyrana::Hooks::Events::AfterInvocationEvent.new(agent: self, request_id: request_id,
                                                                          prompt: prompt, response: output, usage: @last_usage, timestamp: Time.now))
      end
    end

    def messages
      @messages.dup
    end

    attr_reader :last_usage

    def reset!
      @messages.clear
      persist_messages
    end

    def interrupt!(reason: 'interrupted', message: nil)
      @interrupted = Rubyrana::Types::Interrupt.new(reason: reason, message: message)
    end

    def structured_output(prompt, schema: nil, **)
      structured_schema = schema || @default_structured_output_schema
      raise StructuredOutputError, 'Structured output schema is required' unless structured_schema

      @model.structured_output(
        prompt: prompt,
        schema: structured_schema,
        tools: @tool_registry.definitions,
        **
      )
    end

    def event_loop(prompt, structured_output_schema: nil, **)
      Rubyrana::EventLoop::Runner.run(
        agent: self,
        prompt: prompt,
        structured_output_schema: structured_output_schema,
        **
      )
    end

    private

    def symbolize_keys(hash)
      hash.transform_keys(&:to_sym)
    end

    def log_debug(message, **data)
      return unless Rubyrana.config.debug

      Rubyrana.config.logger.debug({ message: message, **data })
    end

    def apply_safety_filters(text)
      value = text.to_s
      @safety_filters.each { |filter| filter.enforce!(value) }
    end

    def build_tool_message(tool, result, _tool_call_id)
      if result.is_a?(Hash)
        {
          role: 'tool',
          name: tool.name,
          content: result[:text] || result['text'] || result.to_json,
          structured: result
        }
      else
        { role: 'tool', name: tool.name, content: result.to_s }
      end
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

    def apply_memory_strategy(messages)
      return messages unless @memory_strategy

      @memory_strategy.apply(messages)
    end

    def build_context(request_id:, prompt:)
      {
        request_id: request_id,
        prompt: prompt,
        session_id: @session_id,
        agent_id: @agent_id,
        model: @model.class.name
      }
    end

    def model_rate_limiter
      Rubyrana.config.model_rate_limiters[@model.class.name]
    end

    def emit_hook_event(event)
      Rubyrana.config.hooks.emit(event)
    end

    def load_session_history
      return unless @session_repository && @session_id && @agent_id
      return unless @messages.empty?

      messages = if @session_repository.respond_to?(:list_all_messages)
                   @session_repository.list_all_messages(@session_id, @agent_id)
                 else
                   @session_repository.list_messages(@session_id, @agent_id)
                 end

      @messages = messages.map do |record|
        { role: record.role, content: record.content }
      end
    end

    def ensure_session_records
      return unless @session_repository && @session_id

      unless @session_repository.read_session(@session_id)
        session = Rubyrana::Session::SessionRecord.new(
          session_id: @session_id,
          metadata: {},
          created_at: Time.now
        )
        @session_repository.create_session(session)
      end

      return if @session_repository.read_agent(@session_id, @agent_id)

      agent_record = Rubyrana::Session::AgentRecord.new(
        session_id: @session_id,
        agent_id: @agent_id,
        metadata: {},
        created_at: Time.now
      )
      @session_repository.create_agent(@session_id, agent_record)
    end

    def persist_session_message(message)
      return unless @session_repository && @session_id && @agent_id

      record = Rubyrana::Session::MessageRecord.new(
        session_id: @session_id,
        agent_id: @agent_id,
        message_id: SecureRandom.uuid,
        role: message[:role],
        content: message[:content],
        created_at: Time.now
      )
      @session_repository.create_message(@session_id, @agent_id, record)
    end
  end
end
