# frozen_string_literal: true

require "json"
require "net/http"
require "openssl"
require "uri"

module Rubyrana
  module Tools
    class WebSearch
      DEFAULT_PROVIDER = "serper"

      def initialize(api_key: ENV["WEB_SEARCH_API_KEY"], provider: DEFAULT_PROVIDER, ssl_cert_file: ENV["SSL_CERT_FILE"])
        @api_key = api_key
        @provider = provider
        @ssl_cert_file = ssl_cert_file
      end

      def tool
        Rubyrana::Tool.new(
          "web_search",
          description: "Search the web and return top results.",
          schema: {
            type: "object",
            properties: {
              query: { type: "string" },
              limit: { type: "number" }
            },
            required: ["query"]
          }
        ) do |query:, limit: 5|
          search(query: query, limit: limit)
        end
      end

      private

      def search(query:, limit: 5)
        raise Rubyrana::ConfigurationError, "WEB_SEARCH_API_KEY not set. Users must supply their own web search API key." unless @api_key

        case @provider
        when "serper"
          serper_search(query: query, limit: limit)
        else
          raise Rubyrana::ConfigurationError, "Unsupported web search provider: #{@provider}"
        end
      end

      def serper_search(query:, limit:)
        uri = URI("https://google.serper.dev/search")
        request = Net::HTTP::Post.new(uri)
        request["X-API-KEY"] = @api_key
        request["Content-Type"] = "application/json"
        request.body = JSON.dump({ q: query, num: limit })

        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          http.ca_file = @ssl_cert_file if @ssl_cert_file && !@ssl_cert_file.empty?
          http.request(request)
        end

        raise Rubyrana::ProviderError, "Web search failed (status #{response.code})" unless response.is_a?(Net::HTTPSuccess)

        body = JSON.parse(response.body)
        results = (body["organic"] || []).first(limit).map do |item|
          {
            title: item["title"],
            url: item["link"],
            snippet: item["snippet"]
          }
        end

        { results: results }.to_json
      rescue JSON::ParserError
        raise Rubyrana::ProviderError, "Invalid web search response"
      end
    end
  end
end
