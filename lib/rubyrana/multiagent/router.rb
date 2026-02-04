# frozen_string_literal: true

module Rubyrana
  module Multiagent
    class Router
      def route(prompt, agents:)
        raise ArgumentError, "agents must not be empty" if agents.nil? || agents.empty?

        scored = agents.map do |agent|
          score = if agent.respond_to?(:match_score)
            agent.match_score(prompt)
          elsif agent.respond_to?(:keywords)
            keyword_score(prompt, agent.keywords)
          else
            0
          end

          [agent, score]
        end

        scored.max_by { |(_, score)| score }.first
      end

      private

      def keyword_score(prompt, keywords)
        return 0 unless keywords

        keywords.sum { |keyword| prompt.to_s.downcase.include?(keyword.to_s.downcase) ? 1 : 0 }
      end
    end
  end
end
