# frozen_string_literal: true

module Rubyrana
  module Providers
    class Base
      def complete(prompt: nil, messages: nil, tools: [], **_opts)
        raise NotImplementedError, "Provider must implement #complete"
      end

      def stream(prompt: nil, messages: nil, tools: [], **_opts, &block)
        result = complete(prompt: prompt, messages: messages, tools: tools, **_opts)
        text = result.is_a?(Hash) ? (result[:text] || result["text"]) : result

        if block_given?
          yield text.to_s
          return
        end

        Enumerator.new do |yielder|
          yielder << text.to_s
        end
      end

      def structured_output(prompt: nil, messages: nil, schema:, tools: [], tool_name: nil, **opts)
        name = tool_name || Rubyrana::Tools::StructuredOutput::Tool::DEFAULT_NAME
        structured_tool = Rubyrana::Tools::StructuredOutput::Tool.new(schema, name: name)
        tool_choice = { type: "tool", name: structured_tool.name }
        base_messages = messages || (prompt ? [{ role: "user", content: prompt }] : [])

        response = complete(
          prompt: prompt,
          messages: base_messages,
          tools: tools + [structured_tool.to_h],
          tool_choice: tool_choice,
          **opts
        )

        output = extract_structured_output(response, structured_tool)
        return output if output

        retry_messages = build_retry_messages(base_messages, response)
        response = complete(
          messages: retry_messages,
          tools: tools + [structured_tool.to_h],
          tool_choice: tool_choice,
          **opts
        )

        output = extract_structured_output(response, structured_tool)
        return output if output

        raise StructuredOutputError, "Model did not return structured output"
      end

      private

      def extract_structured_output(response, structured_tool)
        tool_calls = response[:tool_calls] || response["tool_calls"] || []
        structured_call = tool_calls.find { |call| (call[:name] || call["name"]) == structured_tool.name }
        return nil unless structured_call

        output = structured_call[:arguments] || structured_call["arguments"] || {}
        structured_tool.validate!(output)
        output
      end

      def build_retry_messages(base_messages, response)
        text = response[:text] || response["text"] || ""
        messages = base_messages.dup
        messages << { role: "assistant", content: text } unless text.to_s.empty?
        messages << { role: "user", content: "You must format the previous response as structured output." }
        messages
      end
    end
  end
end
