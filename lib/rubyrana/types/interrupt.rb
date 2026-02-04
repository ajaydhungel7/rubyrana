# frozen_string_literal: true

module Rubyrana
  module Types
    Interrupt = Struct.new(:reason, :message, keyword_init: true)
  end
end
