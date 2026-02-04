# frozen_string_literal: true

require 'bundler/setup'
require 'date'
require 'json'
require 'net/http'
require 'uri'

require 'rubyrana'

MODEL = ENV.fetch('RUBYRANA_MODEL', 'claude-sonnet-4-5-20250929')
CACHE_TTL_SECONDS = Integer(ENV.fetch('FIXTURES_CACHE_TTL', '300'), 10)

LALIGA_SYSTEM_PROMPT = 'You are a LaLiga fixtures assistant. Use fixtures_lookup with league=laliga.'
PREMIER_SYSTEM_PROMPT = 'You are a Premier League fixtures assistant. Use fixtures_lookup with league=premier_league.'
SERIE_A_SYSTEM_PROMPT = 'You are a Serie A fixtures assistant. Use fixtures_lookup with league=serie_a.'
CLASSIFIER_SYSTEM_PROMPT = <<~PROMPT
  Extract leagues and optional date range from the user request.
  Leagues must be from: laliga, premier_league, serie_a.
  If none are explicitly mentioned, return an empty list.
  Dates must be YYYY-MM-DD. If not provided, return nulls.
PROMPT

Rubyrana.configure do |config|
  config.default_provider = Rubyrana::Providers::Anthropic.new(
    api_key: ENV.fetch('ANTHROPIC_API_KEY'),
    model: MODEL
  )
end

fixtures_cache = {}

fixtures_lookup = Rubyrana::Tool.new(
  'fixtures_lookup',
  description: 'Return fixtures for a league from football-data.org',
  schema: {
    type: 'object',
    properties: {
      league: {
        type: 'string',
        enum: %w[laliga premier_league serie_a]
      },
      date_from: { type: 'string', description: 'YYYY-MM-DD' },
      date_to: { type: 'string', description: 'YYYY-MM-DD' }
    },
    required: ['league']
  }
) do |league:, date_from: nil, date_to: nil|
  api_key = ENV.fetch('FOOTBALL_DATA_API_KEY')
  league_codes = {
    'laliga' => 'PD',
    'premier_league' => 'PL',
    'serie_a' => 'SA'
  }

  code = league_codes.fetch(league)
  from = date_from || Date.today.to_s
  to = date_to || (Date.today + 7).to_s

  cache_key = "#{league}|#{from}|#{to}"
  cached = fixtures_cache[cache_key]
  if cached && (Time.now.to_i - cached.fetch(:ts)) < CACHE_TTL_SECONDS
    return cached.fetch(:data)
  end

  uri = URI("https://api.football-data.org/v4/competitions/#{code}/matches")
  uri.query = URI.encode_www_form(dateFrom: from, dateTo: to)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(uri)
  request['X-Auth-Token'] = api_key

  response = http.request(request)
  unless response.is_a?(Net::HTTPSuccess)
    return "API error #{response.code}: #{response.body}"
  end

  payload = JSON.parse(response.body)
  matches = payload.fetch('matches', [])
  result =
    if matches.empty?
      "No fixtures found for #{league} between #{from} and #{to}."
    else
      matches.map do |match|
        date = match.fetch('utcDate')[0, 10]
        home = match.dig('homeTeam', 'name')
        away = match.dig('awayTeam', 'name')
        "#{date}: #{home} vs #{away}"
      end.join("\n")
    end

  fixtures_cache[cache_key] = { ts: Time.now.to_i, data: result }
  result
end

laliga_agent = Rubyrana::Agent.new(tools: [fixtures_lookup])
premier_agent = Rubyrana::Agent.new(tools: [fixtures_lookup])
serie_a_agent = Rubyrana::Agent.new(tools: [fixtures_lookup])

router = Rubyrana::Multiagent::Router.new

classifier = Rubyrana::Agent.new(
  structured_output_schema: {
    type: 'object',
    properties: {
      leagues: {
        type: 'array',
        items: { type: 'string', enum: %w[laliga premier_league serie_a] }
      },
      date_from: { type: %w[string null] },
      date_to: { type: %w[string null] }
    },
    required: %w[leagues date_from date_to]
  }
)

task = ARGV.join(' ').strip
if task.empty?
  puts 'Usage: ruby football_fixtures_orchestrator.rb "fixtures for premier league"'
  exit 1
end

league_to_agent = {
  'laliga' => laliga_agent,
  'premier_league' => premier_agent,
  'serie_a' => serie_a_agent
}

agent_to_system_prompt = {
  laliga_agent => LALIGA_SYSTEM_PROMPT,
  premier_agent => PREMIER_SYSTEM_PROMPT,
  serie_a_agent => SERIE_A_SYSTEM_PROMPT
}

def call_league_agent(agent, league, task, date_from, date_to, system_prompt)
  label =
    if league == 'laliga'
      'LaLiga'
    elsif league == 'premier_league'
      'Premier League'
    else
      'Serie A'
    end

  request =
    if date_from || date_to
      from = date_from || Date.today.to_s
      to = date_to || (Date.today + 7).to_s
      "#{task}\nUse date_from=#{from} and date_to=#{to}."
    else
      task
    end

  "#{label}:\n#{agent.call(request, system: system_prompt)}"
end

extracted = classifier.structured_output(task, system: CLASSIFIER_SYSTEM_PROMPT)
leagues = extracted.fetch('leagues')
date_from = extracted.fetch('date_from')
date_to = extracted.fetch('date_to')

if leagues.empty?
  chosen = router.route(task, agents: league_to_agent.values)
  system_prompt = agent_to_system_prompt.fetch(chosen)
  puts chosen.call(task, system: system_prompt)
elsif leagues.length == 1
  league = leagues.first
  agent = league_to_agent.fetch(league)
  system_prompt = agent_to_system_prompt.fetch(agent)
  puts call_league_agent(agent, league, task, date_from, date_to, system_prompt)
else
  outputs = leagues.map do |league|
    agent = league_to_agent.fetch(league)
    system_prompt = agent_to_system_prompt.fetch(agent)
    call_league_agent(agent, league, task, date_from, date_to, system_prompt)
  end
  puts outputs.join("\n\n")
end
