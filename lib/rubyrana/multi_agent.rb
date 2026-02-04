# frozen_string_literal: true

module Rubyrana
  class MultiAgent
    def initialize(agents:, router: nil)
      @agents = agents
      @router = router
    end

    def call(prompt, **)
      agent = @router ? @router.route(prompt, agents: @agents) : @agents.first
      raise Rubyrana::RoutingError, 'No agents configured' unless agent

      agent.call(prompt, **)
    end

    def broadcast(prompt, **)
      @agents.map { |agent| agent.call(prompt, **) }
    end
  end

  class MultiAgentGraph
    def initialize(nodes:, edges: {}, router: nil)
      @nodes = nodes
      @edges = edges
      @router = router
    end

    def run(start_node:, prompt:, **)
      raise Rubyrana::RoutingError, 'Unknown start node' unless @nodes.key?(start_node)

      current = start_node
      output = prompt
      visited = []

      loop do
        visited << current
        agent = @nodes[current]
        raise Rubyrana::RoutingError, "No agent for node #{current}" unless agent

        output = agent.call(output, **)
        next_node = next_node_for(current, output)
        break unless next_node

        current = next_node
      end

      { output: output, visited: visited }
    end

    private

    def next_node_for(current, output)
      if @router
        routed = @router.route(output, agents: @nodes.values)
        return routed if @nodes.key?(routed)

        return @nodes.key(routed)
      end

      edge = @edges[current]
      edge.respond_to?(:call) ? edge.call(output) : edge
    end
  end
end
