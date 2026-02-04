# frozen_string_literal: true

module Rubyrana
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class ProviderError < Error; end
  class ToolError < Error; end
  class SafetyError < Error; end
  class PersistenceError < Error; end
  class RoutingError < Error; end
  class StructuredOutputError < Error; end
  class SessionError < Error; end
end
