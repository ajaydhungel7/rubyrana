# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class AgentPersistenceTest < Minitest::Test
  def test_agent_persists_messages
    api_key = ENV["ANTHROPIC_API_KEY"]
    model = ENV.fetch("ANTHROPIC_MODEL", "claude-3-haiku-20240307")
    skip "ANTHROPIC_API_KEY not set" unless api_key

    Dir.mktmpdir do |dir|
      store = Rubyrana::Persistence::FileStore.new(directory: dir)
      provider = Rubyrana::Providers::Anthropic.new(api_key: api_key, model: model)

      agent = Rubyrana::Agent.new(model: provider, store: store, session_id: "s1")
      agent.call("Reply with the word: ok")

      agent2 = Rubyrana::Agent.new(model: provider, store: store, session_id: "s1")
      assert_equal 2, agent2.messages.length
    end
  end
end
