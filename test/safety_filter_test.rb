# frozen_string_literal: true

require "test_helper"

class SafetyFilterTest < Minitest::Test
  def test_blocklist_filter
    filter = Rubyrana::Safety::BlocklistFilter.new(patterns: ["blocked"])
    assert_raises(Rubyrana::SafetyError) { filter.enforce!("this is blocked") }
  end

  def test_filter_allows_clean_text
    filter = Rubyrana::Safety::BlocklistFilter.new(patterns: ["blocked"])
    filter.enforce!("all good")
  end
end
