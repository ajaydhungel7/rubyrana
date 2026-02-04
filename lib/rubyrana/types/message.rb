# frozen_string_literal: true

module Rubyrana
  module Types
    Message = Struct.new(:role, :content, :name, :tool_call_id, :structured, keyword_init: true)
  end
end
