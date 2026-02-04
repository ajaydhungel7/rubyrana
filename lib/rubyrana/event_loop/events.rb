# frozen_string_literal: true

module Rubyrana
  module EventLoop
    ModelCallEvent = Struct.new(:messages, :tools, :timestamp, keyword_init: true)
    ModelResponseEvent = Struct.new(:response, :timestamp, keyword_init: true)
    ToolCallEvent = Struct.new(:tool_use, :timestamp, keyword_init: true)
    ToolResultEvent = Struct.new(:tool_name, :result, :timestamp, keyword_init: true)
    MessageEvent = Struct.new(:message, :timestamp, keyword_init: true)
    TextDeltaEvent = Struct.new(:text, :timestamp, keyword_init: true)
    InterruptEvent = Struct.new(:interrupt, :timestamp, keyword_init: true)
    StructuredOutputEvent = Struct.new(:structured_output, keyword_init: true)
    StopEvent = Struct.new(:stop_reason, :message, :usage, :structured_output, :interrupts, keyword_init: true)
  end
end
