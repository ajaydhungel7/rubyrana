# frozen_string_literal: true

require 'test_helper'
require_relative 'mock_agent_tool'
require_relative 'mock_hook_provider'
require_relative 'mock_multiagent_hook_provider'
require_relative 'mock_session_repository'
require_relative 'mocked_model_provider'
require_relative 'tool_with_spec_but_no_function'
require_relative 'tool_with_spec_but_non_callable_function'

class FixturesTest < Minitest::Test
  Session = Struct.new(:session_id)
  SessionAgent = Struct.new(:agent_id)
  SessionMessage = Struct.new(:message_id)
  MultiAgent = Struct.new(:id) do
    def serialize_state
      { id: id }
    end
  end

  def test_mock_agent_tool
    tool = Rubyrana::TestFixtures::MockAgentTool.new('alpha')
    assert_equal 'Mock result for alpha', tool.call
    assert_equal 'alpha', tool.to_h[:name]
    assert_equal 'Mock tool', tool.to_h[:description]
  end

  def test_mock_hook_provider_filters_events
    registry = Rubyrana::Hooks::Registry.new
    provider = Rubyrana::TestFixtures::MockHookProvider.new(%i[before_request on_tool_call])
    provider.register_with(registry)

    registry.before_request({ request_id: '1' })
    registry.after_request({ request_id: '1' })
    registry.on_tool_call({ tool: 'echo' })

    assert_equal %i[before_request on_tool_call], provider.event_types_received
  end

  def test_mock_multiagent_hook_provider_records
    provider = Rubyrana::TestFixtures::MockMultiagentHookProvider.new(%i[before_node_call after_node_call])
    provider.before_node_call({ node: 'a' })
    provider.after_node_call({ node: 'a' })
    provider.after_multiagent_invocation({})

    assert_equal %i[before_node_call after_node_call], provider.event_types_received
  end

  def test_mock_session_repository_lifecycle
    repo = Rubyrana::TestFixtures::MockSessionRepository.new
    session = Session.new('s1')
    agent = SessionAgent.new('a1')
    message = SessionMessage.new('m1')
    multi_agent = MultiAgent.new('ma1')

    repo.create_session(session)
    repo.create_agent('s1', agent)
    repo.create_message('s1', 'a1', message)
    repo.create_multi_agent('s1', multi_agent)

    assert_equal session, repo.read_session('s1')
    assert_equal agent, repo.read_agent('s1', 'a1')
    assert_equal message, repo.read_message('s1', 'a1', 'm1')
    assert_equal [{ id: 'ma1' }], [repo.read_multi_agent('s1', 'ma1')]
    assert_equal [message], repo.list_messages('s1', 'a1')
  end

  def test_mocked_model_provider_complete_and_stream
    provider = Rubyrana::TestFixtures::MockedModelProvider.new([
                                                                 { text: 'hello' },
                                                                 { text: 'world', chunks: %w[w o r l d] }
                                                               ])

    response = provider.complete(messages: [])
    assert_equal 'hello', response[:text]

    streamed = provider.stream(messages: []).to_a
    assert_equal %w[w o r l d], streamed
  end

  def test_say_tool_fixture_registers_tools
    Rubyrana::Tooling.reset!
    load File.expand_path('say_tool.rb', __dir__)

    say_tool = Rubyrana::Tooling.registry.fetch('say')
    dont_say_tool = Rubyrana::Tooling.registry.fetch('dont_say')

    assert_equal 'Hello Ruby!', say_tool.call(input: 'Ruby')
    assert_equal 'Didnt say anything!', dont_say_tool.call(input: 'Ruby')
    assert_equal 'Not a tool!', Rubyrana::TestFixtures.not_a_tool
  end

  def test_tool_specs_constants
    assert_equal({ 'hello' => 'world!' }, Rubyrana::TestFixtures::ToolWithSpecButNoFunction::TOOL_SPEC)
    assert_equal({ 'hello' => 'world' }, Rubyrana::TestFixtures::ToolWithSpecButNonCallableFunction::TOOL_SPEC)
    assert_equal 'not a function!', Rubyrana::TestFixtures::ToolWithSpecButNonCallableFunction::TOOL_FUNCTION
  end
end
