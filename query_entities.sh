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

printf "\nGateway Device\n"

GATEWAY_DEVICE_RESPONSE=$(curl --silent --request GET \
  "${BASE_URL}/devices" \
  --header "Authorization: ${SESSION_API_KEY}" \
  --header 'Accept: application/json' \
  --get \
  --data-urlencode 'page_meta=true' \
  --data-urlencode "unique_id=${GATEWAY_UNIQUE_ID}"
)

printf "\nNumber of values returned: %s\n" "$(jq --raw-output '.total' <<<"${GATEWAY_DEVICE_RESPONSE}")"

GATEWAY_DEVICE=$(jq --raw-output '.resources[0]' <<<"${GATEWAY_DEVICE_RESPONSE}")

printf "\nGateway Device\n %s\n" "${GATEWAY_DEVICE}"

# valid values: online, offline, idle, never_reported
printf "\nGateway Device Heartbeat Status: %s\n" "$(jq --raw-output '.heartbeat_status' <<<"${GATEWAY_DEVICE}")"

printf "\nSensor Device\n"

SENSOR_DEVICE_RESPONSE=$(curl --silent --request GET \
  "${BASE_URL}/devices" \
  --header "Authorization: ${SESSION_API_KEY}" \
  --header 'Accept: application/json' \
  --get \
  --data-urlencode 'page_meta=true' \
  --data-urlencode "unique_id=${SENSOR_UNIQUE_ID}"
)

printf "\nNumber of values returned: %s\n" "$(jq --raw-output '.total' <<<"${SENSOR_DEVICE_RESPONSE}")"

SENSOR_DEVICE=$(jq --raw-output '.resources[0]' <<<"${SENSOR_DEVICE_RESPONSE}")

printf "\Sensor Device\n %s\n" "${SENSOR_DEVICE}"

# valid values: online, offline, idle, never_reported
printf "\nSensor Device Heartbeat Status: %s\n" "$(jq --raw-output '.heartbeat_status' <<<"${SENSOR_DEVICE}")"

printf "\nDevice Query: Tags CONTAINS 'POC'\n"

TAG_QUERY_RESPONSE=$(curl --silent --request GET \
  "${BASE_URL}/devices" \
  --header "Authorization: ${SESSION_API_KEY}" \
  --header 'Accept: application/json' \
  --get \
  --data-urlencode 'page_meta=true' \
  --data-urlencode "tags_inc=poc"
)

printf "\nNumber of values returned: %s\n" "$(jq --raw-output '.total' <<<"${TAG_QUERY_RESPONSE}")"

printf "\nPOC Device summary\n %s\n" "$(jq --raw-output '[.resources[] | {Name: .name, UniqueID: .unique_id}]' <<<"${TAG_QUERY_RESPONSE}")"
