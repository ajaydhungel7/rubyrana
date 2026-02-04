# frozen_string_literal: true

require 'net/http'
require 'json'

module Rubyrana
  module A2A
    class CardResolver
      def initialize(base_url:, http_client: nil)
        @base_url = base_url
        @http_client = http_client
      end

      def get_agent_card
        uri = URI.join(@base_url, '/.well-known/agent-card')
        response = http_client.get(uri)
        raise Rubyrana::ProviderError, "A2A agent card request failed (status #{response.code})" unless response.is_a?(Net::HTTPSuccess)

        body = JSON.parse(response.body)
        Rubyrana::A2A::AgentCard.new(
          name: body['name'],
          description: body['description'],
          url: body['url'],
          version: body['version'],
          capabilities: body['capabilities'],
          default_input_modes: body['default_input_modes'] || [],
          default_output_modes: body['default_output_modes'] || [],
          skills: body['skills'] || []
        )
      rescue JSON::ParserError => e
        raise Rubyrana::ProviderError, e.message
      end

      private

      def http_client
        @http_client ||= Net::HTTP
      end
    end

    class ClientFactory
      def initialize(http_client: nil, streaming: true)
        @http_client = http_client
        @streaming = streaming
      end

      def create(agent_card)
        Client.new(agent_card.url, http_client: @http_client, streaming: @streaming)
      end
    end

    class Client
      def initialize(base_url, http_client: nil, streaming: true)
        @base_url = base_url
        @http_client = http_client || Net::HTTP
        @streaming = streaming
      end

      def send_message(message)
        response = post_message(message)
        parsed = parse_message_response(response)

        Enumerator.new do |yielder|
          yielder << parsed
        end
      end

      private

      def post_message(message)
        uri = URI.join(@base_url, '/messages')
        request = Net::HTTP::Post.new(uri)
        request['Content-Type'] = 'application/json'
        request.body = JSON.dump({ message: serialize_message(message) })

        @http_client.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request(request)
        end
      end

      def parse_message_response(response)
        raise Rubyrana::ProviderError, "A2A message request failed (status #{response.code})" unless response.is_a?(Net::HTTPSuccess)

        body = JSON.parse(response.body)
        message = body['message'] || body
        parts = Array(message['parts']).map { |part| Rubyrana::A2A::Part.new(kind: part['kind'], text: part['text']) }
        Rubyrana::A2A::Message.new(
          message_id: message['message_id'] || SecureRandom.uuid,
          role: message['role'] || 'agent',
          parts: parts
        )
      rescue JSON::ParserError => e
        raise Rubyrana::ProviderError, e.message
      end

      def serialize_message(message)
        {
          message_id: message.message_id,
          role: message.role,
          parts: message.parts.map { |part| { kind: part.kind, text: part.text } }
        }
      end
    end
  end
end
