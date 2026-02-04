# frozen_string_literal: true

module Rubyrana
  module Providers
    class Bedrock < Base
      def initialize(*_args, **_kwargs)
        raise ConfigurationError, 'Bedrock provider is not included in this release'
      end
    end
  end
end
