# frozen_string_literal: true

require "faraday"
require "json"

module Rubyrana
  module Providers
    class Anthropic < Base
      def initialize(api_key:, model:, client: nil)
        @api_key = api_key
        @model = model
        @client = client
      end

      def complete(prompt: nil, messages: nil, tools: [], **_opts)
        resolved_messages = format_messages(messages || [{ role: "user", content: prompt }])
        payload = {
          model: @model,
          max_tokens: 1024,
          messages: resolved_messages
        }

        if tools.any?
          payload[:tools] = tools.map do |tool|
            entry = {
              name: tool[:name],
              input_schema: tool[:input_schema] || { type: "object", properties: {}, required: [] }
            }
            entry[:description] = tool[:description] if tool[:description]
            entry
          end
        end

        response = request_with_retries do
          client.post("/v1/messages") do |req|
            req.headers["x-api-key"] = @api_key
            req.headers["anthropic-version"] = "2023-06-01"
            req.headers["Content-Type"] = "application/json"
            req.body = JSON.dump(payload)
          end
        end

        parse_response(response)
      end

      def stream(prompt: nil, messages: nil, tools: [], **_opts, &block)
        return super unless block_given?

        resolved_messages = format_messages(messages || [{ role: "user", content: prompt }])
        payload = {
          model: @model,
          max_tokens: 1024,
          messages: resolved_messages,
          stream: true
        }

        if tools.any?
          payload[:tools] = tools.map do |tool|
            entry = {
              name: tool[:name],
              input_schema: tool[:input_schema] || { type: "object", properties: {}, required: [] }
            }
            entry[:description] = tool[:description] if tool[:description]
            entry
          end
        end

        stream_request("/v1/messages", payload, &block)
      end

      private

      def client
        @client ||= Faraday.new(url: "https://api.anthropic.com")
      end

      def parse_response(response)
        unless response.success?
          raise ProviderError, "Anthropic request failed (status #{response.status}): #{response.body}"
        end

        body = JSON.parse(response.body)
        assistant_content = body["content"] || []
        text = assistant_content.select { |item| item["type"] == "text" }.map { |item| item["text"] }.join
        tool_calls = assistant_content.select { |item| item["type"] == "tool_use" }.map do |item|
          {
            id: item["id"],
            name: item["name"],
            arguments: item["input"] || {}
          }
        end

        {
          text: text,
          tool_calls: tool_calls,
          usage: body["usage"],
          assistant_content: assistant_content
        }
      rescue JSON::ParserError
        raise ProviderError, "Invalid response from Anthropic"
      end

      def stream_request(path, payload, &block)
        buffer = String.new

        request_with_retries do
          client.post(path) do |req|
            req.headers["x-api-key"] = @api_key
            req.headers["anthropic-version"] = "2023-06-01"
            req.headers["Content-Type"] = "application/json"
            req.options.on_data = proc do |chunk, _|
              buffer << chunk
              while (line = buffer.slice!(/.*\n/))
                line = line.strip
                next unless line.start_with?("data:")

                data = line.delete_prefix("data:").strip
                next if data == "[DONE]"

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
        return event.dig("delta", "text") if event["type"] == "content_block_delta"
        return event.dig("content_block", "text") if event["type"] == "content_block_start"

        nil
      end

      def format_messages(messages)
        messages.map do |message|
          role = message[:role] || message["role"]
          content = message[:content] || message["content"]

          if role == "tool"
            tool_use_id = message[:tool_call_id] || message["tool_call_id"]
            {
              role: "user",
              content: [
                {
                  type: "tool_result",
                  tool_use_id: tool_use_id,
                  content: content.to_s
                }
              ]
            }
          else
            { role: role, content: content }
          end
        end
      end

      def request_with_retries(max_retries: 2)
        attempts = 0
        begin
          attempts += 1
          yield
        rescue Faraday::Error => e
          retry if attempts <= max_retries
          raise ProviderError, e.message
        end
      end
    end
  end
end
