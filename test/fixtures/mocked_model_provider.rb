# frozen_string_literal: true

module Rubyrana
  module TestFixtures
    class MockedModelProvider < Rubyrana::Providers::Base
      attr_reader :calls, :index

      def initialize(agent_responses)
        @agent_responses = agent_responses.dup
        @index = 0
        @calls = []
      end

      def complete(prompt: nil, messages: nil, tools: [], **_opts)
        @calls << { prompt: prompt, messages: messages, tools: tools }
        response = @agent_responses[@index] || {}
        @index += 1
        response
      end

      def stream(prompt: nil, messages: nil, tools: [], **, &)
        response = complete(prompt: prompt, messages: messages, tools: tools, **)
        text = response.is_a?(Hash) ? (response[:text] || response['text'] || '') : response.to_s
        chunks = response.is_a?(Hash) ? (response[:chunks] || response['chunks']) : nil
        payloads = Array(chunks || [text])

        if block_given?
          payloads.each(&)
          return
        end

        Enumerator.new do |yielder|
          payloads.each { |chunk| yielder << chunk }
        end
      end
    end
  end
end
