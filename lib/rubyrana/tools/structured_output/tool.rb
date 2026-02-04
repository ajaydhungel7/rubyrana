# frozen_string_literal: true

module Rubyrana
  module Tools
    module StructuredOutput
      class Tool
        DEFAULT_NAME = '__structured_output__'

        attr_reader :name, :schema

        def initialize(schema, name: DEFAULT_NAME)
          @name = name.to_s
          @schema = schema.is_a?(Rubyrana::Tools::StructuredOutput::Schema) ? schema.to_h : schema
        end

        def description
          'Return structured output that matches the provided schema.'
        end

        def to_h
          {
            name: name,
            description: description,
            input_schema: schema
          }
        end

        def validate!(value)
          raise Rubyrana::StructuredOutputError, 'Structured output must be an object' unless value.is_a?(Hash)

          required = schema[:required] || schema['required'] || []
          required.each do |key|
            next if value.key?(key.to_sym) || value.key?(key.to_s)

            raise Rubyrana::StructuredOutputError, "Missing required structured output field: #{key}"
          end
        end
      end
    end
  end
end
