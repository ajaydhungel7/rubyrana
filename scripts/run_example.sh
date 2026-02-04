#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: scripts/run_example.sh <path-to-example>"
  exit 1
fi

cd "$(dirname "$0")/.."

rbenv exec bundle exec ruby "$1"
