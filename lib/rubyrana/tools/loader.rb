# frozen_string_literal: true

module Rubyrana
  module Tools
    class Loader
      def initialize(directory)
        @directory = directory
      end

      def load
        return [] unless Dir.exist?(@directory)

        before = Rubyrana::Tooling.tools.dup
        Dir[File.join(@directory, "**/*.rb")].sort.each { |file| require file }
        after = Rubyrana::Tooling.tools
        (after - before)
      end
    end
  end
end
