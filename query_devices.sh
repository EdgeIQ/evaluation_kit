#!/usr/bin/env bash

# Assumes the following tools are installed
# * curl - tested against version 7.64.1
# * jq - tested against version 1.6 (https://stedolan.github.io/jq)
# * HTTPie - tested against version 2.1.0 (https://httpie.org/)

# Will exit script if we would use an uninitialised variable (nounset) or when a
# simple command (not a control structure) fails (errexit)
set -eu

function print_error() {
  read -r line file <<<"$(caller)"
  echo "An error occurred in line ${line} of file ${file}:" >&2
  sed "${line}q;d" "${file}" >&2
}

trap print_error ERR

if ! [[ -x "$(command -v http)" ]]; then
  echo 'HTTPie is required. Please install from https://httpie.org/ and try again.'
  exit 1
fi

if ! [[ -x "$(command -v jq)" ]]; then
  echo 'jq is required. Please install from https://stedolan.github.io/jq and try again.'
  exit 1
fi

# Get directory this script is located in to access script local files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

source "${SCRIPT_DIR}/setenv.sh"

# Get temporaray session token
SESSION_AUTH_RESULT=$(
  http --json --body POST "${BASE_URL}/user/authenticate" \
    "email=${ADMIN_EMAIL}" \
    "password=${ADMIN_PASSWORD}"
)

if [[ "${SESSION_AUTH_RESULT}" == *'Not authorized'* ]]; then
  printf "Invalid Credentials\n"
  exit
fi

SESSION_API_KEY=$(jq --raw-output '.session_token' <<<"${SESSION_AUTH_RESULT}")

printf "\nGateway Device\n"

GATEWAY_DEVICE_RESPONSE=$(
  http --json --body GET "${BASE_URL}/devices" \
    "Authorization:${SESSION_API_KEY}" \
    'page_meta==true' \
    "unique_id==${GATEWAY_UNIQUE_ID}"
)

printf "\nNumber of values returned: %s\n" "$(jq --raw-output '.total' <<<"${GATEWAY_DEVICE_RESPONSE}")"

GATEWAY_DEVICE=$(jq --raw-output '.resources[0]' <<<"${GATEWAY_DEVICE_RESPONSE}")

printf "\nGateway Device\n %s\n" "$(jq --color-output <<<"${GATEWAY_DEVICE}")"

# valid values: online, offline, idle, never_reported
printf "\nGateway Device Heartbeat Status: %s\n" "$(jq --raw-output '.heartbeat_status' <<<"${GATEWAY_DEVICE}")"

printf "\nSensor Device\n"

SENSOR_DEVICE_RESPONSE=$(
  http --json --body GET "${BASE_URL}/devices" \
    "Authorization:${SESSION_API_KEY}" \
    'page_meta==true' \
    "unique_id==${SENSOR_UNIQUE_ID}"
)

printf "\nNumber of values returned: %s\n" "$(jq --raw-output '.total' <<<"${SENSOR_DEVICE_RESPONSE}")"

SENSOR_DEVICE=$(jq --raw-output '.resources[0]' <<<"${SENSOR_DEVICE_RESPONSE}")

printf "\nSensor Device\n %s\n" "$(jq --color-output <<<"${SENSOR_DEVICE}")"

# valid values: online, offline, idle, never_reported
printf "\nSensor Device Heartbeat Status: %s\n" "$(jq --raw-output '.heartbeat_status' <<<"${SENSOR_DEVICE}")"

printf "\nSensor Device with 'unique_id' less than 'dd'\n"

SENSOR_DEVICE_RESPONSE=$(
  http --json --body GET "${BASE_URL}/devices" \
    "Authorization:${SESSION_API_KEY}" \
    'page_meta==true' \
    "unique_id_lt==dd"
)

printf "\nNumber of values returned: %s\n" "$(jq --raw-output '.total' <<<"${SENSOR_DEVICE_RESPONSE}")"

printf "\nSensor Device\n %s\n" "$(jq --color-output '[.resources[] | .unique_id]' <<<"${SENSOR_DEVICE_RESPONSE}")"

printf "\nDevice Query: 'tags' array CONTAINS 'POC'\n"

TAG_QUERY_RESPONSE=$(
  http --json --body GET "${BASE_URL}/devices" \
    "Authorization:${SESSION_API_KEY}" \
    'page_meta==true' \
    'tags_inc==poc'
)

printf "\nNumber of values returned: %s\n" "$(jq --raw-output '.total' <<<"${TAG_QUERY_RESPONSE}")"

printf "\nPOC Device summary\n %s\n" "$(jq --color-output '[.resources[] | {name,unique_id}]' <<<"${TAG_QUERY_RESPONSE}")"
