# frozen_string_literal: true

require 'test_helper'

class SessionRedisRepositoryTest < Minitest::Test
  class FakeRedis
    def initialize
      @store = {}
    end

    def get(key)
      @store[key]
    end

    def set(key, value)
      @store[key] = value
    end
  end

  def test_redis_repository_round_trip
    redis = FakeRedis.new
    repo = Rubyrana::Session::RedisRepository.new(redis: redis)

    session = Rubyrana::Session::SessionRecord.new(session_id: 's1', metadata: {}, created_at: Time.now)
    agent = Rubyrana::Session::AgentRecord.new(session_id: 's1', agent_id: 'a1', metadata: {}, created_at: Time.now)
    message = Rubyrana::Session::MessageRecord.new(session_id: 's1', agent_id: 'a1', message_id: 'm1', role: 'user',
                                                   content: 'hi', created_at: Time.now)

    repo.create_session(session)
    repo.create_agent('s1', agent)
    repo.create_message('s1', 'a1', message)

    assert_equal session.session_id, repo.read_session('s1').session_id
    assert_equal agent.agent_id, repo.read_agent('s1', 'a1').agent_id
    assert_equal message.message_id, repo.read_message('s1', 'a1', 'm1').message_id
  end
end
