# frozen_string_literal: true

require 'json'

module Rubyrana
  module Session
    class RedisRepository < Repository
      def initialize(redis:, namespace: 'rubyrana:sessions')
        @redis = redis
        @namespace = namespace
      end

      def create_session(session)
        write_session(session)
      end

      def read_session(session_id)
        data = read_data(session_id)
        return nil unless data

        SessionRecord.new(**data.fetch('session'))
      end

      def create_agent(session_id, session_agent)
        data = ensure_data(session_id)
        agents = data['agents']
        if agents.key?(session_agent.agent_id)
          raise Rubyrana::SessionError,
                "Agent #{session_agent.agent_id} already exists in session #{session_id}"
        end

        agents[session_agent.agent_id] = session_agent.to_h
        write_data(session_id, data)
      end

      def read_agent(session_id, agent_id)
        data = read_data(session_id)
        return nil unless data

        agent = data['agents'][agent_id]
        agent ? AgentRecord.new(**agent) : nil
      end

      def update_agent(session_id, session_agent)
        data = ensure_data(session_id)
        agents = data['agents']
        unless agents.key?(session_agent.agent_id)
          raise Rubyrana::SessionError,
                "Agent #{session_agent.agent_id} does not exist in session #{session_id}"
        end

        agents[session_agent.agent_id] = session_agent.to_h
        write_data(session_id, data)
      end

      def create_message(session_id, agent_id, session_message)
        data = ensure_data(session_id)
        messages = data['messages'][agent_id] ||= {}
        if messages.key?(session_message.message_id)
          raise Rubyrana::SessionError,
                "Message #{session_message.message_id} already exists in agent #{agent_id} in session #{session_id}"
        end

        messages[session_message.message_id] = session_message.to_h
        write_data(session_id, data)
      end

      def read_message(session_id, agent_id, message_id)
        data = read_data(session_id)
        return nil unless data

        message = data['messages'].fetch(agent_id, {})[message_id]
        message ? MessageRecord.new(**message) : nil
      end

      def update_message(session_id, agent_id, session_message)
        data = ensure_data(session_id)
        messages = data['messages'].fetch(agent_id, {})
        unless messages.key?(session_message.message_id)
          raise Rubyrana::SessionError,
                "Message #{session_message.message_id} does not exist in session #{session_id}"
        end

        messages[session_message.message_id] = session_message.to_h
        data['messages'][agent_id] = messages
        write_data(session_id, data)
      end

      def list_messages(session_id, agent_id, limit: nil, offset: 0)
        data = read_data(session_id)
        return [] unless data

        messages = data['messages'].fetch(agent_id, {})
        sorted = messages.values.map { |value| MessageRecord.new(**value) }.sort_by(&:created_at)
        return sorted[offset, limit] if limit

        sorted.drop(offset)
      end

      def create_multi_agent(session_id, multi_agent)
        data = ensure_data(session_id)
        data['multi_agents'][multi_agent.id] = serialize_multi_agent(multi_agent)
        write_data(session_id, data)
      end

      def read_multi_agent(session_id, multi_agent_id)
        data = read_data(session_id)
        return nil unless data

        data['multi_agents'][multi_agent_id]
      end

      def update_multi_agent(session_id, multi_agent)
        data = ensure_data(session_id)
        unless data['multi_agents'].key?(multi_agent.id)
          raise Rubyrana::SessionError,
                "MultiAgent #{multi_agent.id} does not exist in session #{session_id}"
        end

        data['multi_agents'][multi_agent.id] = serialize_multi_agent(multi_agent)
        write_data(session_id, data)
      end

      private

      def write_session(session)
        data = default_data(session.session_id)
        data['session'] = session.to_h
        write_data(session.session_id, data)
      end

      def default_data(session_id)
        {
          'session' => { 'session_id' => session_id, 'metadata' => {}, 'created_at' => Time.now },
          'agents' => {},
          'messages' => {},
          'multi_agents' => {}
        }
      end

      def ensure_data(session_id)
        data = read_data(session_id)
        raise Rubyrana::SessionError, "Session #{session_id} does not exist" unless data

        data
      end

      def read_data(session_id)
        raw = @redis.get(key(session_id))
        return nil unless raw

        JSON.parse(raw)
      rescue JSON::ParserError => e
        raise Rubyrana::SessionError, e.message
      end

      def write_data(session_id, data)
        @redis.set(key(session_id), JSON.dump(data))
      end

      def key(session_id)
        "#{@namespace}:#{session_id}"
      end

      def serialize_multi_agent(multi_agent)
        return multi_agent.serialize_state if multi_agent.respond_to?(:serialize_state)

        multi_agent
      end
    end
  end
end
