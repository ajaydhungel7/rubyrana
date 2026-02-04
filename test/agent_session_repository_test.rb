# frozen_string_literal: true

require 'test_helper'
require_relative 'fixtures/mocked_model_provider'

class AgentSessionRepositoryTest < Minitest::Test
  def test_agent_persists_messages_in_session_repository
    responses = [{ text: 'Hello' }]
    provider = Rubyrana::TestFixtures::MockedModelProvider.new(responses)
    repository = Rubyrana::Session::InMemoryRepository.new

    agent = Rubyrana::Agent.new(
      model: provider,
      session_repository: repository,
      session_id: 's1',
      agent_id: 'a1'
    )

    result = agent.call('Hi')
    assert_equal 'Hello', result

    messages = repository.list_messages('s1', 'a1')
    assert_equal 2, messages.length
    assert_equal 'user', messages[0].role
    assert_equal 'Hi', messages[0].content
    assert_equal 'assistant', messages[1].role
    assert_equal 'Hello', messages[1].content
  end

  def test_agent_persists_tool_messages
    responses = [
      { text: '', tool_calls: [{ name: 'echo', arguments: { text: 'hi' } }] },
      { text: 'Done' }
    ]
    provider = Rubyrana::TestFixtures::MockedModelProvider.new(responses)
    repository = Rubyrana::Session::InMemoryRepository.new
    tool = Rubyrana::Tool.new('echo') { |text:| text }

    agent = Rubyrana::Agent.new(
      model: provider,
      tools: [tool],
      session_repository: repository,
      session_id: 's1',
      agent_id: 'a1'
    )

    result = agent.call('Hi')
    assert_equal 'Done', result

    messages = repository.list_messages('s1', 'a1')
    assert_equal 3, messages.length
    assert_equal 'user', messages[0].role
    assert_equal 'tool', messages[1].role
    assert_equal 'assistant', messages[2].role
  end
end
