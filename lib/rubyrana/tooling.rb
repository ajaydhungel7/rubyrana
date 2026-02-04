# frozen_string_literal: true

module Rubyrana
  module Tooling
    @registry = Rubyrana::ToolRegistry.new

    class << self
      attr_reader :registry

      def reset!
        @registry = Rubyrana::ToolRegistry.new
      end

      def register(tool)
        @registry.register(tool)
        tool
      end

      def tools
        @registry.all
      end

      def define(name, description: nil, schema: nil, &)
        tool = Rubyrana::Tool.new(name, description: description, schema: schema, &)
        register(tool)
      end
    end
  end

  def self.tool(name, description: nil, schema: nil, &)
    Tooling.define(name, description: description, schema: schema, &)
  end
end
