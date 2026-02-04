# frozen_string_literal: true

module Rubyrana
  module Hooks
    module Events
      AgentInitializedEvent = Struct.new(:agent, :timestamp, keyword_init: true)
      BeforeInvocationEvent = Struct.new(:agent, :request_id, :prompt, :timestamp, keyword_init: true)
      AfterInvocationEvent = Struct.new(:agent, :request_id, :prompt, :response, :usage, :timestamp, keyword_init: true)
      BeforeModelCallEvent = Struct.new(:agent, :request_id, :messages, :tools, :timestamp, keyword_init: true)
      AfterModelCallEvent = Struct.new(:agent, :request_id, :response, :timestamp, keyword_init: true)
      BeforeToolCallEvent = Struct.new(:agent, :request_id, :tool_name, :arguments, :timestamp, keyword_init: true)
      AfterToolCallEvent = Struct.new(:agent, :request_id, :tool_name, :result, :timestamp, keyword_init: true)
      MessageAddedEvent = Struct.new(:agent, :request_id, :message, :timestamp, keyword_init: true)
    end
  end
end
