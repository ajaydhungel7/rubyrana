# frozen_string_literal: true

module MCPTestIO
  class FakeStdout
    def initialize(lines)
      @lines = lines.dup
      @closed = false
    end

    def gets
      @lines.shift
    end

    def close
      @closed = true
    end

    def closed?
      @closed
    end
  end

  class FakeStderr < FakeStdout; end
end
