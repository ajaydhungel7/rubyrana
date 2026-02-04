# frozen_string_literal: true

require 'dotenv/load'
require 'rubyrana'

# Define tools in a separate folder using Rubyrana.tool
# Example file: ./tools/hello_tool.rb
# Rubyrana.tool("hello") { |name:| "Hello, #{name}!" }

Rubyrana.configure do |config|
  config.default_provider = Rubyrana::Providers::Anthropic.new(
    api_key: ENV.fetch('ANTHROPIC_API_KEY'),
    model: ENV.fetch('ANTHROPIC_MODEL', 'claude-3-haiku-20240307')
  )
end

agent = Rubyrana::Agent.new(load_tools_from: './tools')
puts agent.call('Use the hello tool to greet Ajay')
