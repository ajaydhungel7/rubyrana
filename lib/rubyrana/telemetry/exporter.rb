# frozen_string_literal: true

module Rubyrana
  module Telemetry
    class Exporter
      def export(_payload)
        raise NotImplementedError, 'Exporter must implement #export'
      end
    end
  end
end
