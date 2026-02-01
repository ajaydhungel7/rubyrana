# frozen_string_literal: true

module Rubyrana
  module Routing
    class KeywordRouter
      def initialize(routes: {}, default_index: 0)
        @routes = routes
        @default_index = default_index
      end

      def route(prompt, agents:)
        match = @routes.find { |keyword, _| prompt.to_s.downcase.include?(keyword.to_s.downcase) }
        index = match ? match[1] : @default_index
        agents.fetch(index)
      rescue IndexError
        raise Rubyrana::RoutingError, "No agent found for route"
      end
    end
  end
end
