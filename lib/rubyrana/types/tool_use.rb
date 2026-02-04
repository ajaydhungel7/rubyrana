# frozen_string_literal: true

module Rubyrana
  module Types
    ToolUse = Struct.new(:name, :arguments, :tool_call_id, keyword_init: true)
  end
end
