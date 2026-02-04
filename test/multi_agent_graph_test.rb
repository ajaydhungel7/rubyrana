# frozen_string_literal: true

require "test_helper"

class MultiAgentGraphTest < Minitest::Test
  def test_graph_runs_through_nodes
    agent_a = Minitest::Mock.new
    agent_b = Minitest::Mock.new

    agent_a.expect(:call, "next", ["start"])
    agent_b.expect(:call, "done", ["next"])

    graph = Rubyrana::MultiAgentGraph.new(
      nodes: { a: agent_a, b: agent_b },
      edges: { a: :b }
    )

    result = graph.run(start_node: :a, prompt: "start")

    assert_equal "done", result[:output]
    assert_equal [:a, :b], result[:visited]

    agent_a.verify
    agent_b.verify
  end
end
