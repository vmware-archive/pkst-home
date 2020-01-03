#!/usr/bin/env bash

set -e

# https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GITHUB_PRIVATE_KEY=$(lpass show "Shared-PKS Telemetry/[github] pkstelemetrybot-private-key" --notes)
TOOLSMITHS_API_KEY="$(lpass show "Shared-PKS Telemetry/Toolsmiths API Key" --notes)"
SLACK_WEBHOOK=$(lpass show "Shared-PKS Telemetry/Slack Webhook" --url)

fly -t hh set-pipeline \
  --config ${DIR}/pipeline.yml \
  --pipeline pks-telemetry-env-renewal \
  --var github-private-key="${GITHUB_PRIVATE_KEY}" \
  --var toolsmiths-api-key="${TOOLSMITHS_API_KEY}" \
  --var slack-webhook="${SLACK_WEBHOOK}"
