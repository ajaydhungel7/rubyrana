# frozen_string_literal: true

module Rubyrana
  module Providers
    class OpenAI < Base
      def initialize(*_args, **_kwargs)
        raise ConfigurationError, 'OpenAI provider is not included in this release'
      end
    end
  end
end
