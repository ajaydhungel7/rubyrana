# frozen_string_literal: true

require "test_helper"

class MultiAgentTest < Minitest::Test
  class FakeAgent
    def initialize(name)
      @name = name
    end

    def call(prompt, **_opts)
      "#{@name}: #{prompt}"
    end
  end

  def test_multi_agent_routing
    agent1 = FakeAgent.new("a1")
    agent2 = FakeAgent.new("a2")
    router = Rubyrana::Routing::KeywordRouter.new(routes: { "billing" => 1 }, default_index: 0)

    multi = Rubyrana::MultiAgent.new(agents: [agent1, agent2], router: router)
    assert_equal "a2: billing question", multi.call("billing question")
  end

  def test_multi_agent_broadcast
    agent1 = FakeAgent.new("a1")
    agent2 = FakeAgent.new("a2")
    multi = Rubyrana::MultiAgent.new(agents: [agent1, agent2])

    results = multi.broadcast("ping")
    assert_equal ["a1: ping", "a2: ping"], results
  end
end
