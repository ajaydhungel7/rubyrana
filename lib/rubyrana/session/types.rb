# frozen_string_literal: true

module Rubyrana
  module Session
    SessionRecord = Struct.new(:session_id, :metadata, :created_at, keyword_init: true)
    AgentRecord = Struct.new(:session_id, :agent_id, :metadata, :created_at, keyword_init: true)
    MessageRecord = Struct.new(:session_id, :agent_id, :message_id, :role, :content, :created_at, keyword_init: true)
  end
end
