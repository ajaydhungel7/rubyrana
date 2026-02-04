# frozen_string_literal: true

require 'json'
require 'time'

module Rubyrana
  module Telemetry
    class JsonlExporter < Exporter
      def initialize(path:)
        @path = path
      end

      def export(payload)
        directory = File.dirname(@path)
        FileUtils.mkdir_p(directory)
        File.open(@path, 'a') do |file|
          file.puts(JSON.dump(payload.merge({ timestamp: Time.now.utc.iso8601 })))
        end
      end
    end
  end
end
