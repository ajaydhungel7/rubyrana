# frozen_string_literal: true

require 'test_helper'

class RoutingTest < Minitest::Test
  def test_keyword_router
    a1 = Object.new
    a2 = Object.new
    router = Rubyrana::Routing::KeywordRouter.new(routes: { 'billing' => 1 }, default_index: 0)

    assert_equal a2, router.route('billing issue', agents: [a1, a2])
    assert_equal a1, router.route('general', agents: [a1, a2])
  end
end
