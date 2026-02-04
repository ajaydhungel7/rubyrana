# frozen_string_literal: true

require "test_helper"

class MemoryStrategyTest < Minitest::Test
  def test_rolling_window_trims
    strategy = Rubyrana::Memory::RollingWindow.new(max_messages: 2)
    messages = [
      { role: "user", content: "a" },
      { role: "assistant", content: "b" },
      { role: "user", content: "c" }
    ]

    trimmed = strategy.apply(messages)
    assert_equal 2, trimmed.length
    assert_equal "b", trimmed[0][:content]
    assert_equal "c", trimmed[1][:content]
  end
end
