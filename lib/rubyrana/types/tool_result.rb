# frozen_string_literal: true

module Rubyrana
  module Types
    ToolResult = Struct.new(:text, :structured, keyword_init: true)
  end
end
