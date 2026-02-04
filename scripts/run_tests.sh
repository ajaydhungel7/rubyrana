#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

rbenv exec bundle exec ruby -Itest -e "Dir['test/**/*_test.rb'].each { |f| require_relative f }"
