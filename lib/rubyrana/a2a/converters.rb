# frozen_string_literal: true

module Rubyrana
  module A2A
    module Converters
      module_function

      def convert_input_to_message(prompt)
        return prompt if prompt.is_a?(Rubyrana::A2A::Message)

        if prompt.is_a?(Hash)
          role = prompt[:role] || prompt['role'] || 'user'
          content = prompt[:content] || prompt['content'] || ''
          return build_message(role, content)
        end

        return build_message('user', prompt) if prompt.is_a?(Array)

        build_message('user', prompt.to_s)
      end

      def convert_response_to_agent_result(event)
        message = extract_message(event)
        text = extract_text_from_message(message)
        Rubyrana::Types::AgentResult.new(
          text: text,
          message: message,
          stop_reason: 'end_turn',
          tool_results: [],
          tool_uses: [],
          interrupts: []
        )
      end

      def build_message(role, content)
        parts = normalize_parts(content)
        Rubyrana::A2A::Message.new(
          message_id: SecureRandom.uuid,
          role: role,
          parts: parts
        )
      end

      def normalize_parts(content)
        return content.map { |item| to_part(item) } if content.is_a?(Array)

        [to_part(content)]
      end

      def to_part(item)
        return item if item.is_a?(Rubyrana::A2A::Part) || item.is_a?(Rubyrana::A2A::TextPart)

        if item.is_a?(Hash)
          kind = item[:kind] || item['kind'] || 'text'
          text = item[:text] || item['text'] || item[:content] || item['content'] || item.to_s
          return Rubyrana::A2A::Part.new(kind: kind, text: text)
        end

        Rubyrana::A2A::TextPart.new(kind: 'text', text: item.to_s)
      end

      def extract_message(event)
        return message_to_hash(event) if event.is_a?(Rubyrana::A2A::Message)

        if event.is_a?(Array) && event.length == 2
          task = event[0]
          return message_to_hash(task.message) if task.respond_to?(:message) && task.message
        end

        if event.is_a?(Hash)
          return event if event.key?(:role) || event.key?('role')
          return event[:message] || event['message'] if event[:message] || event['message']
        end

        { role: 'assistant', content: [{ text: event.to_s }] }
      end

      def message_to_hash(message)
        content = message.parts.to_a.map { |part| { text: part.text } }
        { role: message.role, content: content }
      end

      def extract_text_from_message(message)
        content = message[:content] || message['content'] || []
        content.map { |item| item[:text] || item['text'] }.compact.join
      end
    end
  end
end
