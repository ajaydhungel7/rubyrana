# frozen_string_literal: true

require 'faraday'
require 'json'

module Rubyrana
  module Providers
    class Anthropic < Base
      def initialize(api_key:, model:, client: nil, timeout: 60, retry_policy: nil, circuit_breaker: nil)
        @api_key = api_key
        @model = model
        @client = client
        @timeout = timeout
        @retry_policy = retry_policy
        @circuit_breaker = circuit_breaker
      end

      def complete(prompt: nil, messages: nil, tools: [], system: nil, tool_choice: nil, max_tokens: 1024,
                   temperature: nil, top_p: nil, stop_sequences: nil, metadata: nil, extra: nil, **_opts)
        resolved_messages = format_messages(messages || [{ role: 'user', content: prompt }])
        payload = build_payload(
          messages: resolved_messages,
          tools: tools,
          system: system,
          tool_choice: tool_choice,
          max_tokens: max_tokens,
          temperature: temperature,
          top_p: top_p,
          stop_sequences: stop_sequences,
          metadata: metadata,
          extra: extra
        )

        response = with_retry do
          client.post('/v1/messages') do |req|
            req.headers['x-api-key'] = @api_key
            req.headers['anthropic-version'] = '2023-06-01'
            req.headers['Content-Type'] = 'application/json'
            req.body = JSON.dump(payload)
          end
        end

        parse_response(response)
      end

      def stream(prompt: nil, messages: nil, tools: [], system: nil, tool_choice: nil, max_tokens: 1024,
                 temperature: nil, top_p: nil, stop_sequences: nil, metadata: nil, extra: nil, **_opts, &)
        return super unless block_given?

        resolved_messages = format_messages(messages || [{ role: 'user', content: prompt }])
        payload = build_payload(
          messages: resolved_messages,
          tools: tools,
          system: system,
          tool_choice: tool_choice,
          max_tokens: max_tokens,
          temperature: temperature,
          top_p: top_p,
          stop_sequences: stop_sequences,
          metadata: metadata,
          extra: extra,
          stream: true
        )

        stream_request('/v1/messages', payload, &)
      end

      private

      def client
        @client ||= Faraday.new(url: 'https://api.anthropic.com') do |builder|
          builder.options.timeout = @timeout
          builder.options.open_timeout = @timeout
        end
      end

      def parse_response(response)
        raise ProviderError, "Anthropic request failed (status #{response.status}): #{response.body}" unless response.success?

        body = JSON.parse(response.body)
        assistant_content = body['content'] || []
        text = assistant_content.select { |item| item['type'] == 'text' }.map { |item| item['text'] }.join
        tool_calls = assistant_content.select { |item| item['type'] == 'tool_use' }.map do |item|
          {
            id: item['id'],
            name: item['name'],
            arguments: item['input'] || {}
          }
        end

        {
          text: text,
          tool_calls: tool_calls,
          usage: body['usage'],
          assistant_content: assistant_content
        }
      rescue JSON::ParserError
        raise ProviderError, 'Invalid response from Anthropic'
      end

      def stream_request(path, payload, &block)
        buffer = String.new

        with_retry do
          client.post(path) do |req|
            req.headers['x-api-key'] = @api_key
            req.headers['anthropic-version'] = '2023-06-01'
            req.headers['Content-Type'] = 'application/json'
            req.options.on_data = proc do |chunk, _|
              buffer << chunk
              while (line = buffer.slice!(/.*\n/))
                line = line.strip
                next unless line.start_with?('data:')

                data = line.delete_prefix('data:').strip
                next if data == '[DONE]'

                begin
                  event = JSON.parse(data)
                  delta = extract_stream_delta(event)
                  block.call(delta) if delta && !delta.empty?
                rescue JSON::ParserError
                  next
                end
              end
            end
            req.body = JSON.dump(payload)
          end
        end
      end

      def extract_stream_delta(event)
        return event.dig('delta', 'text') if event['type'] == 'content_block_delta'
        return event.dig('content_block', 'text') if event['type'] == 'content_block_start'

        nil
      end

      def build_payload(messages:, tools:, system:, tool_choice:, max_tokens:, temperature:, top_p:, stop_sequences:,
                        metadata:, extra:, stream: false)
        payload = {
          model: @model,
          max_tokens: max_tokens,
          messages: messages
        }

        payload[:system] = system if system
        payload[:tool_choice] = tool_choice if tool_choice
        payload[:temperature] = temperature if temperature
        payload[:top_p] = top_p if top_p
        payload[:stop_sequences] = stop_sequences if stop_sequences
        payload[:metadata] = metadata if metadata
        payload[:stream] = true if stream

        if tools.any?
          payload[:tools] = tools.map do |tool|
            entry = {
              name: tool[:name],
              input_schema: tool[:input_schema] || { type: 'object', properties: {}, required: [] }
            }
            entry[:description] = tool[:description] if tool[:description]
            entry
          end
        end

        payload.merge!(extra) if extra.is_a?(Hash)
        payload
      end

      def format_messages(messages)
        messages.map do |message|
          role = message[:role] || message['role']
          content = message[:content] || message['content']

          if role == 'tool'
            tool_use_id = message[:tool_call_id] || message['tool_call_id']
            structured = message[:structured] || message['structured']
            tool_content = structured || message[:content] || message['content']
            tool_content = if tool_content.is_a?(Hash)
                             content_blocks = tool_content[:content] || tool_content['content']
                             content_blocks.is_a?(Array) ? content_blocks : tool_content.to_json
                           elsif tool_content.is_a?(Array)
                             tool_content
                           else
                             tool_content.to_s
                           end
            {
              role: 'user',
              content: [
                {
                  type: 'tool_result',
                  tool_use_id: tool_use_id,
                  content: tool_content
                }
              ]
            }
          else
            { role: role, content: content }
          end
        end
      end

      def with_retry
        policy = @retry_policy || Rubyrana.config.retry_policy
        breaker = @circuit_breaker || Rubyrana.config.circuit_breaker
        raise ProviderError, 'Circuit breaker open' unless breaker.allow_request?

        policy.run do
          response = yield
          raise Rubyrana::Retry::RetryableError, "Anthropic request failed (status #{response.status})" if retryable_status?(response.status)

          breaker.record_success
          response
        end
      rescue Rubyrana::Retry::RetryableError, Faraday::Error => e
        breaker&.record_failure
        raise ProviderError, e.message
      end

      def retryable_status?(status)
        [408, 429, 500, 502, 503, 504].include?(status)
      end
    end
  end
end
