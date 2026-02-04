# frozen_string_literal: true

require 'dotenv/load'
require 'rubyrana'

Rubyrana.configure do |config|
  config.default_provider = Rubyrana::Providers::Anthropic.new(
    api_key: ENV.fetch('ANTHROPIC_API_KEY'),
    model: ENV.fetch('ANTHROPIC_MODEL', 'claude-3-haiku-20240307')
  )
end

agent = Rubyrana::Agent.new

agent.stream('Give me a one-line summary of Ruby.') do |chunk|
  print chunk
end

puts
