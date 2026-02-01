# frozen_string_literal: true

module Rubyrana
  class Tool
    attr_reader :name, :description, :schema

    def initialize(name, description: nil, schema: nil, &block)
      raise ToolError, "Tool requires a block" unless block_given?

      @name = name.to_s
      @description = description
      @schema = schema
      @block = block
    end

    def call(**kwargs)
      @block.call(**kwargs)
    rescue StandardError => e
      raise ToolError, e.message
    end

    def to_h
      {
        name: name,
        description: description,
        input_schema: schema || { type: "object", properties: {}, required: [] }
      }
    end
  end
end
