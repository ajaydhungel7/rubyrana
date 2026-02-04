# frozen_string_literal: true

module Rubyrana
  module Types
    AgentResult = Struct.new(
      :text,
      :structured_output,
      :usage,
      :message,
      :stop_reason,
      :tool_results,
      :tool_uses,
      :interrupts,
      keyword_init: true
    )
  end
end
