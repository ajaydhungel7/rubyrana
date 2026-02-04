# frozen_string_literal: true

module Rubyrana
  module Safety
    class Filter
      def check(_text)
        []
      end

      def enforce!(text)
        violations = check(text)
        return if violations.empty?

        raise Rubyrana::SafetyError, "Safety filter triggered: #{violations.join(', ')}" if violations.any?
      end
    end

    class BlocklistFilter < Filter
      def initialize(patterns: [])
        @patterns = patterns.map { |p| p.is_a?(Regexp) ? p : /#{Regexp.escape(p)}/i }
      end

      def check(text)
        @patterns.select { |pattern| pattern.match?(text) }.map(&:source)
      end
    end
  end
end
