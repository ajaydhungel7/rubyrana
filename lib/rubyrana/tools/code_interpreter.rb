# frozen_string_literal: true

require 'json'
require 'open3'
require 'tempfile'
require 'timeout'

module Rubyrana
  module Tools
    class CodeInterpreter
      DEFAULT_TIMEOUT = 5

      def initialize(timeout_s: DEFAULT_TIMEOUT, ruby_bin: 'ruby')
        @timeout_s = timeout_s
        @ruby_bin = ruby_bin
      end

      def tool
        Rubyrana::Tool.new(
          'code_interpreter',
          description: 'Run Ruby code in a temporary process and return stdout/stderr.',
          schema: {
            type: 'object',
            properties: {
              code: { type: 'string' },
              timeout_s: { type: 'number' }
            },
            required: ['code']
          }
        ) do |code:, timeout_s: nil|
          execute(code: code, timeout_s: timeout_s)
        end
      end

      private

      def execute(code:, timeout_s: nil)
        timeout_value = (timeout_s || @timeout_s).to_f

        Tempfile.create(['rubyrana', '.rb']) do |file|
          file.write(code)
          file.flush

          stdout, stderr, status = run_with_timeout(file.path, timeout_value)
          {
            stdout: stdout,
            stderr: stderr,
            exit_status: status&.exitstatus
          }.to_json
        end
      rescue Timeout::Error
        { stdout: '', stderr: 'Execution timed out', exit_status: nil }.to_json
      end

      def run_with_timeout(path, timeout_value)
        stdout = ''
        stderr = ''
        status = nil

        Timeout.timeout(timeout_value) do
          stdout, stderr, status = Open3.capture3(@ruby_bin, path)
        end

        [stdout, stderr, status]
      end
    end
  end
end
