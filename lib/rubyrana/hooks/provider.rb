# frozen_string_literal: true

module Rubyrana
  module Hooks
    class Provider
      def register_hooks(_registry)
        raise NotImplementedError, 'Hook provider must implement #register_hooks'
      end
    end
  end
end
