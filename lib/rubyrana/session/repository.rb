# frozen_string_literal: true

module Rubyrana
  module Session
    class Repository
      def create_session(_session)
        raise NotImplementedError, "Repository must implement #create_session"
      end

      def read_session(_session_id)
        raise NotImplementedError, "Repository must implement #read_session"
      end

      def create_agent(_session_id, _session_agent)
        raise NotImplementedError, "Repository must implement #create_agent"
      end

      def read_agent(_session_id, _agent_id)
        raise NotImplementedError, "Repository must implement #read_agent"
      end

      def update_agent(_session_id, _session_agent)
        raise NotImplementedError, "Repository must implement #update_agent"
      end

      def create_message(_session_id, _agent_id, _session_message)
        raise NotImplementedError, "Repository must implement #create_message"
      end

      def read_message(_session_id, _agent_id, _message_id)
        raise NotImplementedError, "Repository must implement #read_message"
      end

      def update_message(_session_id, _agent_id, _session_message)
        raise NotImplementedError, "Repository must implement #update_message"
      end

      def list_messages(_session_id, _agent_id, limit: nil, offset: 0)
        raise NotImplementedError, "Repository must implement #list_messages"
      end

      def create_multi_agent(_session_id, _multi_agent)
        raise NotImplementedError, "Repository must implement #create_multi_agent"
      end

      def read_multi_agent(_session_id, _multi_agent_id)
        raise NotImplementedError, "Repository must implement #read_multi_agent"
      end

      def update_multi_agent(_session_id, _multi_agent)
        raise NotImplementedError, "Repository must implement #update_multi_agent"
      end
    end

    class InMemoryRepository < Repository
      attr_reader :sessions, :agents, :messages, :multi_agents

      def initialize
        @sessions = {}
        @agents = {}
        @messages = {}
        @multi_agents = {}
      end

      def list_all_messages(session_id, agent_id)
        list_messages(session_id, agent_id)
      end

      def create_session(session)
        session_id = session.session_id
        raise Rubyrana::SessionError, "Session #{session_id} already exists" if @sessions.key?(session_id)

        @sessions[session_id] = session
        @agents[session_id] = {}
        @messages[session_id] = {}
        @multi_agents[session_id] = {}
      end

      def read_session(session_id)
        @sessions[session_id]
      end

      def create_agent(session_id, session_agent)
        ensure_session!(session_id)
        agent_id = session_agent.agent_id
        raise Rubyrana::SessionError, "Agent #{agent_id} already exists in session #{session_id}" if @agents[session_id].key?(agent_id)

        @agents[session_id][agent_id] = session_agent
        @messages[session_id][agent_id] = {}
        session_agent
      end

      def read_agent(session_id, agent_id)
        return nil unless @sessions.key?(session_id)

        @agents.dig(session_id, agent_id)
      end

      def update_agent(session_id, session_agent)
        ensure_session!(session_id)
        agent_id = session_agent.agent_id
        raise Rubyrana::SessionError, "Agent #{agent_id} does not exist in session #{session_id}" unless @agents[session_id].key?(agent_id)

        @agents[session_id][agent_id] = session_agent
      end

      def create_message(session_id, agent_id, session_message)
        ensure_session!(session_id)
        ensure_agent!(session_id, agent_id)
        message_id = session_message.message_id
        raise Rubyrana::SessionError, "Message #{message_id} already exists in agent #{agent_id} in session #{session_id}" if @messages[session_id][agent_id].key?(message_id)

        @messages[session_id][agent_id][message_id] = session_message
      end

      def read_message(session_id, agent_id, message_id)
        return nil unless @sessions.key?(session_id)
        return nil unless @agents[session_id].key?(agent_id)

        @messages[session_id][agent_id][message_id]
      end

      def update_message(session_id, agent_id, session_message)
        ensure_session!(session_id)
        ensure_agent!(session_id, agent_id)
        message_id = session_message.message_id
        raise Rubyrana::SessionError, "Message #{message_id} does not exist in session #{session_id}" unless @messages[session_id][agent_id].key?(message_id)

        @messages[session_id][agent_id][message_id] = session_message
      end

      def list_messages(session_id, agent_id, limit: nil, offset: 0)
        return [] unless @sessions.key?(session_id)
        return [] unless @agents[session_id].key?(agent_id)

        messages = @messages[session_id][agent_id]
        sorted = messages.values.sort_by(&:created_at)
        return sorted[offset, limit] if limit

        sorted.drop(offset)
      end

      def create_multi_agent(session_id, multi_agent)
        ensure_session!(session_id)
        multi_agent_id = multi_agent.id
        @multi_agents[session_id][multi_agent_id] = serialize_multi_agent(multi_agent)
      end

      def read_multi_agent(session_id, multi_agent_id)
        return nil unless @sessions.key?(session_id)

        @multi_agents[session_id][multi_agent_id]
      end

      def update_multi_agent(session_id, multi_agent)
        ensure_session!(session_id)
        multi_agent_id = multi_agent.id
        raise Rubyrana::SessionError, "MultiAgent #{multi_agent_id} does not exist in session #{session_id}" unless @multi_agents[session_id].key?(multi_agent_id)

        @multi_agents[session_id][multi_agent_id] = serialize_multi_agent(multi_agent)
      end

      private

      def ensure_session!(session_id)
        raise Rubyrana::SessionError, "Session #{session_id} does not exist" unless @sessions.key?(session_id)
      end

      def ensure_agent!(session_id, agent_id)
        raise Rubyrana::SessionError, "Agent #{agent_id} does not exist in session #{session_id}" unless @agents[session_id].key?(agent_id)
      end

      def serialize_multi_agent(multi_agent)
        return multi_agent.serialize_state if multi_agent.respond_to?(:serialize_state)

        multi_agent
      end
    end
  end
end
