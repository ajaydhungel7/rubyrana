# frozen_string_literal: true

require "test_helper"

class HooksProviderTest < Minitest::Test
  class DemoProvider < Rubyrana::Hooks::Provider
    attr_reader :events

    def initialize
      @events = []
    end

    def register_hooks(registry)
      registry.add_callback(Rubyrana::Hooks::Events::BeforeInvocationEvent) { |event| @events << event }
    end
  end

  def test_register_provider
    provider = DemoProvider.new
    registry = Rubyrana::Hooks::Registry.new
    registry.register_provider(provider)

    event = Rubyrana::Hooks::Events::BeforeInvocationEvent.new(agent: nil, request_id: "1", prompt: "hi", timestamp: Time.now)
    registry.emit(event)

    assert_equal 1, provider.events.length
  end
end
