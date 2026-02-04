# frozen_string_literal: true

module Rubyrana
  module A2A
    class Agent
      DEFAULT_TIMEOUT = 300

      attr_reader :endpoint, :timeout, :name, :description

      def initialize(endpoint:, name: nil, description: nil, timeout: DEFAULT_TIMEOUT, a2a_client_factory: nil, card_resolver: nil)
        @endpoint = endpoint
        @name = name
        @description = description
        @timeout = timeout
        @agent_card = nil
        @a2a_client_factory = a2a_client_factory
        @card_resolver = card_resolver
      end

      def call(prompt = nil, **_kwargs)
        invoke(prompt)
      end

      def invoke(prompt = nil, **_kwargs)
        result = nil
        stream(prompt) do |event|
          result = event[:result] if event[:result]
        end
        raise RuntimeError, "No response received from A2A agent" unless result

        result
      end

      def stream(prompt = nil, **_kwargs)
        raise ArgumentError, "prompt is required" if prompt.nil?

        last_event = nil
        last_complete_event = nil
        enumerator = _send_message(prompt)

        if block_given?
          enumerator.each do |event|
            last_event = event
            last_complete_event = event if complete_event?(event)
            yield({ type: "a2a_stream", event: event })
          end
          final_event = last_complete_event || last_event
          if final_event
            result = Rubyrana::A2A::Converters.convert_response_to_agent_result(final_event)
            yield({ result: result })
          end
          return
        end

        Enumerator.new do |yielder|
          enumerator.each do |event|
            last_event = event
            last_complete_event = event if complete_event?(event)
            yielder << { type: "a2a_stream", event: event }
          end

          final_event = last_complete_event || last_event
          if final_event
            result = Rubyrana::A2A::Converters.convert_response_to_agent_result(final_event)
            yielder << { result: result }
          end
        end
      end

      def get_agent_card
        return @agent_card if @agent_card

        resolver = @card_resolver || Rubyrana::A2A::CardResolver.new(base_url: endpoint)
        @agent_card = resolver.get_agent_card

        @name ||= @agent_card.name
        @description ||= @agent_card.description

        @agent_card
      end

      private

      def _send_message(prompt)
        message = Rubyrana::A2A::Converters.convert_input_to_message(prompt)
        client = a2a_client
        client.send_message(message)
      end

      def a2a_client
        agent_card = get_agent_card
        factory = @a2a_client_factory || Rubyrana::A2A::ClientFactory.new
        factory.create(agent_card)
      end

      def complete_event?(event)
        return true if event.is_a?(Rubyrana::A2A::Message)

        if event.is_a?(Array) && event.length == 2
          task, update_event = event
          return true if update_event.nil?

          if update_event.is_a?(Rubyrana::A2A::TaskArtifactUpdateEvent)
            return update_event.last_chunk unless update_event.last_chunk.nil?
            return false
          end

          if update_event.is_a?(Rubyrana::A2A::TaskStatusUpdateEvent)
            return update_event.status.state == "completed" if update_event.status&.state
          end

          return false
        end

        false
      end
    end
  end
end
