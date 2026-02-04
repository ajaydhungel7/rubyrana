# frozen_string_literal: true

require 'test_helper'

class WebSearchTest < Minitest::Test
  def test_web_search_requires_key
    tool = Rubyrana::Tools.web_search(api_key: nil)
    assert_raises(Rubyrana::ToolError) { tool.call(query: 'ruby') }
  end
end
