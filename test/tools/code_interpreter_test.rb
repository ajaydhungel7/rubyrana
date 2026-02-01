# frozen_string_literal: true

require "test_helper"
require "json"

class CodeInterpreterTest < Minitest::Test
  def test_code_interpreter_runs_ruby
    tool = Rubyrana::Tools.code_interpreter
    result = JSON.parse(tool.call(code: "puts 2 + 2"))

    assert_equal "4\n", result["stdout"]
    assert_equal "", result["stderr"]
  end
end
