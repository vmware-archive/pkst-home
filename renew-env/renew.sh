#!/bin/bash

# Toolsmiths Environment Renewal

[ -z "$DEBUG" ] || set -x
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"

api_url="https://environments.toolsmiths.cf-app.com"
api_gcp_endpoint="/v1/custom_gcp/pks"

function main() {
  echo -e "Starting Toolsmiths Environment Renewal at $(date)"

  cleanup
  setup

  env_names=$(curl -s "${api_url}${api_gcp_endpoint}/list?api_token=${TOOLSMITHS_API_KEY}" | jq .[].name -r)

  for env in ${env_names}; do

    echo -e "\nRenewing environment [${env}]"

    response=$(curl -s "${api_url}${api_gcp_endpoint}/renew" \
                    -H "Content-Type: application/json" \
                    -d "{ \
                          \"api_token\": \"${TOOLSMITHS_API_KEY}\", \
                          \"name\": \"${env}\" \
                        }")

    if [ $? == 0 ]; then
      echo "$(echo $response | jq .message -r)"
    else
      echo "Failed to renew environment [${env}]"
    fi

  done

  cleanup
  echo -e "\nFinished Toolsmiths Environment Renewal at $(date)\n"
}

function setup() {
  : ${TOOLSMITHS_API_KEY:?"Toolsmiths API key must be provided"}
  mkdir -p ${script_dir}/tmp
}

function cleanup() {
  rm -rf ${script_dir}/tmp || 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

exit 0
