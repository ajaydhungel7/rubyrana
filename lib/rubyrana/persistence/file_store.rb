# frozen_string_literal: true

require 'json'
require 'fileutils'

module Rubyrana
  module Persistence
    class FileStore < Base
      def initialize(directory: '.rubyrana')
        @directory = directory
        FileUtils.mkdir_p(@directory)
      end

      def load(session_id)
        path = file_path(session_id)
        return [] unless File.exist?(path)

        JSON.parse(File.read(path))
      rescue StandardError => e
        raise Rubyrana::PersistenceError, e.message
      end

      def save(session_id, messages)
        path = file_path(session_id)
        File.write(path, JSON.pretty_generate(messages))
        true
      rescue StandardError => e
        raise Rubyrana::PersistenceError, e.message
      end

      private

      def file_path(session_id)
        File.join(@directory, "#{session_id}.json")
      end
    end
  end
end
