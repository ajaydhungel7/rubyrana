# frozen_string_literal: true

module Rubyrana
  class MultiAgent
    def initialize(agents:, router: nil)
      @agents = agents
      @router = router
    end

    def call(prompt, **opts)
      agent = @router ? @router.route(prompt, agents: @agents) : @agents.first
      raise Rubyrana::RoutingError, "No agents configured" unless agent

      agent.call(prompt, **opts)
    end

    def broadcast(prompt, **opts)
      @agents.map { |agent| agent.call(prompt, **opts) }
    end
  end
end
