# frozen_string_literal: true

require 'dotenv/load'
require 'rubyrana'

Rubyrana.configure do |config|
  config.debug = true
  config.default_provider = Rubyrana::Providers::Anthropic.new(
    api_key: ENV.fetch('ANTHROPIC_API_KEY'),
    model: ENV.fetch('ANTHROPIC_MODEL', 'claude-3-haiku-20240307')
  )
end

word_count = Rubyrana::Tool.new('word_count') do |text:|
  text.split.size
end

built_in_tools = [
  Rubyrana::Tools.code_interpreter
]

agent = Rubyrana::Agent.new(tools: [word_count] + built_in_tools)
puts agent.call('How many words are in this sentence?')
