# frozen_string_literal: true

module Rubyrana
  module A2A
    AgentCard = Struct.new(
      :name,
      :description,
      :url,
      :version,
      :capabilities,
      :default_input_modes,
      :default_output_modes,
      :skills,
      keyword_init: true
    )

    TextPart = Struct.new(:kind, :text, keyword_init: true)
    Part = Struct.new(:kind, :text, keyword_init: true)

    Message = Struct.new(:message_id, :role, :parts, keyword_init: true)

    Task = Struct.new(:id, :status, :message, keyword_init: true)
    TaskStatus = Struct.new(:state, keyword_init: true)
    TaskStatusUpdateEvent = Struct.new(:status, keyword_init: true)
    TaskArtifactUpdateEvent = Struct.new(:last_chunk, keyword_init: true)
  end
end
