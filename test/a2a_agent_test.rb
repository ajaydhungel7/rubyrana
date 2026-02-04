# frozen_string_literal: true

require "test_helper"

class A2AAgentTest < Minitest::Test
  def test_init_with_defaults
    agent = Rubyrana::A2A::Agent.new(endpoint: "http://localhost:8000")
    assert_equal "http://localhost:8000", agent.endpoint
    assert_equal 300, agent.timeout
    assert_nil agent.name
    assert_nil agent.description
  end

  def test_init_with_name_and_description
    agent = Rubyrana::A2A::Agent.new(endpoint: "http://localhost:8000", name: "my-agent", description: "My custom agent")
    assert_equal "my-agent", agent.name
    assert_equal "My custom agent", agent.description
  end

  def test_get_agent_card_populates_name_and_description
    card = Rubyrana::A2A::AgentCard.new(name: "test-agent", description: "Test agent", url: "http://localhost:8000")
    resolver = Minitest::Mock.new
    resolver.expect(:get_agent_card, card)

    agent = Rubyrana::A2A::Agent.new(endpoint: "http://localhost:8000", card_resolver: resolver)
    result = agent.get_agent_card

    assert_equal card, result
    assert_equal "test-agent", agent.name
    assert_equal "Test agent", agent.description
    resolver.verify
  end

  def test_get_agent_card_cached
    card = Rubyrana::A2A::AgentCard.new(name: "test-agent", description: "Test agent", url: "http://localhost:8000")
    resolver = Minitest::Mock.new
    resolver.expect(:get_agent_card, card)

    agent = Rubyrana::A2A::Agent.new(endpoint: "http://localhost:8000", card_resolver: resolver)
    first = agent.get_agent_card
    second = agent.get_agent_card

    assert_equal first, second
    resolver.verify
  end

  def test_invoke_success
    card = Rubyrana::A2A::AgentCard.new(name: "test-agent", description: "Test agent", url: "http://localhost:8000")
    resolver = Minitest::Mock.new
    resolver.expect(:get_agent_card, card)

    client = Minitest::Mock.new
    message = Rubyrana::A2A::Message.new(message_id: "1", role: "agent", parts: [Rubyrana::A2A::TextPart.new(kind: "text", text: "Response")])
    client.expect(:send_message, [message].to_enum, [Rubyrana::A2A::Message])

    factory = Minitest::Mock.new
    factory.expect(:create, client, [card])

    agent = Rubyrana::A2A::Agent.new(endpoint: "http://localhost:8000", card_resolver: resolver, a2a_client_factory: factory)
    result = agent.invoke("Hello")

    assert_instance_of Rubyrana::Types::AgentResult, result
    assert_equal "Response", result.message[:content][0][:text]
    factory.verify
    client.verify
  end

  def test_invoke_no_prompt
    agent = Rubyrana::A2A::Agent.new(endpoint: "http://localhost:8000")
    assert_raises(ArgumentError) { agent.stream(nil).to_a }
  end

  def test_stream_yields_events_and_result
    card = Rubyrana::A2A::AgentCard.new(name: "test-agent", description: "Test agent", url: "http://localhost:8000")
    resolver = Minitest::Mock.new
    resolver.expect(:get_agent_card, card)

    client = Minitest::Mock.new
    message = Rubyrana::A2A::Message.new(message_id: "1", role: "agent", parts: [Rubyrana::A2A::TextPart.new(kind: "text", text: "Response")])
    client.expect(:send_message, [message].to_enum, [Rubyrana::A2A::Message])

    factory = Minitest::Mock.new
    factory.expect(:create, client, [card])

    agent = Rubyrana::A2A::Agent.new(endpoint: "http://localhost:8000", card_resolver: resolver, a2a_client_factory: factory)
    events = agent.stream("Hello").to_a

    assert_equal 2, events.length
    assert_equal "a2a_stream", events[0][:type]
    assert_equal message, events[0][:event]
    assert_instance_of Rubyrana::Types::AgentResult, events[1][:result]
    assert_equal "Response", events[1][:result].message[:content][0][:text]

    factory.verify
    client.verify
  end
end
