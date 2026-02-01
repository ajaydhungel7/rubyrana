# frozen_string_literal: true

module Rubyrana
  class ToolRegistry
    def initialize(tools = [])
      @tools = {}
      tools.each { |tool| register(tool) }
    end

    def register(tool)
      @tools[tool.name] = tool
    end

    def fetch(name)
      @tools[name.to_s]
    end

    def all
      @tools.values
    end

    def definitions
      all.map(&:to_h)
    end
  end
end
