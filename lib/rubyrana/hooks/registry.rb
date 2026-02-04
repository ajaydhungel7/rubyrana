# frozen_string_literal: true

module Rubyrana
  module Hooks
    class Registry
      def initialize
        @hooks = []
        @callbacks = Hash.new { |hash, key| hash[key] = [] }
        @providers = []
      end

      def register(hook)
        raise ArgumentError, 'Hook must respond to at least one hook method' unless valid_hook?(hook)

        @hooks << hook
      end

      def register_provider(provider)
        raise ArgumentError, 'Hook provider must respond to register_hooks' unless provider.respond_to?(:register_hooks)

        provider.register_hooks(self)
        @providers << provider
        provider
      end

      def add_callback(event_class, callable = nil, &block)
        handler = callable || block
        raise ArgumentError, 'Callback required' unless handler

        id = SecureRandom.uuid
        @callbacks[event_class] << { id: id, handler: handler }
        id
      end

      def remove_callback(event_class, callback_id)
        @callbacks[event_class].reject! { |entry| entry[:id] == callback_id }
      end

      def emit(event)
        @callbacks[event.class].each { |entry| entry[:handler].call(event) }
      end

      def register_proc(before_request: nil, after_request: nil, on_tool_call: nil, on_tool_result: nil)
        hook = Object.new
        hook.define_singleton_method(:before_request, &before_request) if before_request
        hook.define_singleton_method(:after_request, &after_request) if after_request
        hook.define_singleton_method(:on_tool_call, &on_tool_call) if on_tool_call
        hook.define_singleton_method(:on_tool_result, &on_tool_result) if on_tool_result
        register(hook)
        hook
      end

      def before_request(context)
        @hooks.each { |hook| hook.before_request(context) if hook.respond_to?(:before_request) }
      end

      def after_request(context)
        @hooks.each { |hook| hook.after_request(context) if hook.respond_to?(:after_request) }
      end

      def on_tool_call(context)
        @hooks.each { |hook| hook.on_tool_call(context) if hook.respond_to?(:on_tool_call) }
      end

      def on_tool_result(context)
        @hooks.each { |hook| hook.on_tool_result(context) if hook.respond_to?(:on_tool_result) }
      end

      private

      def valid_hook?(hook)
        hook.respond_to?(:before_request) || hook.respond_to?(:after_request) ||
          hook.respond_to?(:on_tool_call) || hook.respond_to?(:on_tool_result)
      end
    end
  end
end
