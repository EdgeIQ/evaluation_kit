#!/usr/bin/env bash

# Assumes the following tools are installed
# * curl - tested against version 7.64.1
# * jq - test against version 1.6 (https://stedolan.github.io/jq)

# Will exit script if we would use an uninitialised variable (nounset) or when a
# simple command (not a control structure) fails (errexit)
set -eu

function print_error() {
  read -r line file <<<"$(caller)"
  echo "An error occurred in line ${line} of file ${file}:" >&2
  sed "${line}q;d" "${file}" >&2
}

trap print_error ERR

# Get directory this script is located in to access script local files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

source "${SCRIPT_DIR}/setenv.sh"

# Get temporaray session token
SESSION_API_KEY=$(
  curl --silent --request POST \
    "${BASE_URL}/user/authenticate" \
    --data @- <<EOF | jq --raw-output '.session_token'
{
  "email": "${ADMIN_EMAIL}",
  "password": "${ADMIN_PASSWORD}"
}
EOF
)

printf "\nDevices\n"

curl --silent --request GET \
  "${BASE_URL}/devices" \
  --header "Authorization: ${SESSION_API_KEY}" \
  --header 'Accept: application/json'

printf "\nDevice Types\n"

curl --silent --request GET \
  "${BASE_URL}/device_types" \
  --header "Authorization: ${SESSION_API_KEY}" \
  --header 'Accept: application/json'

printf "\nIngestors\n"

curl --silent --request GET \
  "${BASE_URL}/ingestors" \
  --header "Authorization: ${SESSION_API_KEY}" \
  --header 'Accept: application/json'

printf "\nTranslators\n"

curl --silent --request GET \
  "${BASE_URL}/translators" \
  --header "Authorization: ${SESSION_API_KEY}" \
  --header 'Accept: application/json'

printf "\nRules\n"

curl --silent --request GET \
  "${BASE_URL}/rules" \
  --header "Authorization: ${SESSION_API_KEY}" \
  --header 'Accept: application/json'
