# frozen_string_literal: true

module Rubyrana
  module TestFixtures
    module ToolWithSpecButNonCallableFunction
      TOOL_SPEC = { 'hello' => 'world' }.freeze
      TOOL_FUNCTION = 'not a function!'
    end
  end
end
