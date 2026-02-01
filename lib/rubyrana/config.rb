# frozen_string_literal: true

require "logger"

module Rubyrana
  class Config
    attr_accessor :logger, :default_provider, :debug

    def initialize
      @logger = Logger.new($stdout)
      @default_provider = nil
      @debug = false
    end
  end
end
