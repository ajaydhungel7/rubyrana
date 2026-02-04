# frozen_string_literal: true

module Rubyrana
  module TestFixtures
    Rubyrana.tool(
      'say',
      description: 'Say something.',
      schema: {
        type: 'object',
        properties: { input: { type: 'string' } },
        required: ['input']
      }
    ) do |input:|
      "Hello #{input}!"
    end

    Rubyrana.tool(
      'dont_say',
      description: 'Dont say something.',
      schema: {
        type: 'object',
        properties: { input: { type: 'string' } },
        required: ['input']
      }
    ) do |input:|
      _input = input
      'Didnt say anything!'
    end

    def self.not_a_tool
      'Not a tool!'
    end
  end
end
