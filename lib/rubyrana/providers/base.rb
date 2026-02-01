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
    end
  end
end
