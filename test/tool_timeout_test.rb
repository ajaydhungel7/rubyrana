# frozen_string_literal: true

require 'test_helper'
require_relative 'fixtures/mocked_model_provider'

class ToolTimeoutTest < Minitest::Test
  def test_tool_timeout_raises
    responses = [
      {
        text: '',
        tool_calls: [
          { name: 'slow', arguments: {} }
        ]
      }
    ]
    provider = Rubyrana::TestFixtures::MockedModelProvider.new(responses)
    tool = Rubyrana::Tool.new('slow') { sleep 0.1 }
    agent = Rubyrana::Agent.new(model: provider, tools: [tool])

    error = assert_raises(Rubyrana::ToolError) do
      agent.call('Hi', tool_timeout: 0.01)
    end
    assert_match(/exceeded timeout/, error.message)
  end
end
