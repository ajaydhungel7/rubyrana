# frozen_string_literal: true

module Rubyrana
  module Tools
    module StructuredOutput
      class Schema
        def initialize(schema)
          @schema = schema
        end

        def to_h
          @schema
        end
      end
    end
  end
end
