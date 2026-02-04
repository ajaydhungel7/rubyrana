# frozen_string_literal: true

module Rubyrana
  module Hooks
    class Base
      def before_request(_context); end
      def after_request(_context); end
      def on_tool_call(_context); end
      def on_tool_result(_context); end
    end
  end
end
