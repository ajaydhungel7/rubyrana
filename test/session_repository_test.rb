# frozen_string_literal: true

require "test_helper"

class SessionRepositoryTest < Minitest::Test
  def setup
    @repo = Rubyrana::Session::InMemoryRepository.new
  end

  def test_session_agent_message_lifecycle
    session = Rubyrana::Session::SessionRecord.new(session_id: "s1", metadata: {}, created_at: Time.now)
    agent = Rubyrana::Session::AgentRecord.new(session_id: "s1", agent_id: "a1", metadata: {}, created_at: Time.now)
    message = Rubyrana::Session::MessageRecord.new(session_id: "s1", agent_id: "a1", message_id: "m1", role: "user", content: "hi", created_at: Time.now)

    @repo.create_session(session)
    @repo.create_agent("s1", agent)
    @repo.create_message("s1", "a1", message)

    assert_equal session, @repo.read_session("s1")
    assert_equal agent, @repo.read_agent("s1", "a1")
    assert_equal message, @repo.read_message("s1", "a1", "m1")
    assert_equal [message], @repo.list_messages("s1", "a1")
  end

  def test_multi_agent_state
    session = Rubyrana::Session::SessionRecord.new(session_id: "s1", metadata: {}, created_at: Time.now)
    @repo.create_session(session)

    multi_agent = Struct.new(:id) do
      def serialize_state
        { id: id, nodes: 2 }
      end
    end

    instance = multi_agent.new("ma1")
    @repo.create_multi_agent("s1", instance)

    assert_equal({ id: "ma1", nodes: 2 }, @repo.read_multi_agent("s1", "ma1"))

    instance2 = multi_agent.new("ma1")
    @repo.update_multi_agent("s1", instance2)

    assert_equal({ id: "ma1", nodes: 2 }, @repo.read_multi_agent("s1", "ma1"))
  end

  def test_errors_for_missing_session
    assert_raises(Rubyrana::SessionError) do
      @repo.create_agent("missing", Rubyrana::Session::AgentRecord.new(session_id: "missing", agent_id: "a", metadata: {}, created_at: Time.now))
    end
  end
end
