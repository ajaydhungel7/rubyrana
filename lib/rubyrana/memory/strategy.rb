# frozen_string_literal: true

module Rubyrana
  module Memory
    class Strategy
      def initialize(max_messages: 20)
        @max_messages = max_messages
      end

      def apply(messages)
        return messages if messages.length <= @max_messages

        messages.last(@max_messages)
      end
    end

    class RollingWindow < Strategy
    end

    class Summarized < Strategy
      def initialize(max_messages: 20, summary_tool: nil)
        super(max_messages: max_messages)
        @summary_tool = summary_tool
      end

      def apply(messages)
        return messages if messages.length <= @max_messages
        return messages.last(@max_messages) unless @summary_tool

        summary = @summary_tool.call(text: messages.map { |m| m[:content] || m["content"] }.join("\n"))
        summary_message = { role: "assistant", content: summary.to_s, summary: true }
        trimmed = messages.last(@max_messages - 1)
        [summary_message] + trimmed
       end
     end
   end
 end
