#!/usr/bin/env bash

# Assumes the following tools are installed
# * curl - tested against version 7.64.1
# * jq - tested against version 1.6 (https://stedolan.github.io/jq)

# Environment assumptions

# Get directory this script is located in to access script local files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

source "${SCRIPT_DIR}/../setenv.sh"
source "${SCRIPT_DIR}/../common_scripts.sh"

# Will exit script if we would use an uninitialised variable (nounset) or when a
# simple command (not a control structure) fails (errexit)
set -eu
trap print_error ERR
trap "exit 1" TERM
export TOP_PID=$$

validate_environment

SESSION_API_KEY=$(get_session_api_key)

# see also https://dev.edgeiq.io/reference#get_device_types
device_types_result=$(
  curl --silent --request GET \
  --url "${BASE_URL}/device_types" \
  --header 'accept: application/json' \
  --header "authorization: ${SESSION_API_KEY}" \
  --header 'content-type: application/json'
)
pretty_print_json 'All Device Types' "${device_types_result}"

# see also https://dev.edgeiq.io/reference#get_devices
devices_result=$(
  curl --silent --request GET \
  --url "${BASE_URL}/devices" \
  --header 'accept: application/json' \
  --header "authorization: ${SESSION_API_KEY}" \
  --header 'content-type: application/json'
)
pretty_print_json 'All Devices' "${devices_result}"

# Paging example
# see also https://dev.edgeiq.io/docs/api-overrview#paging
page_devices_result=$(
  curl --silent --request GET \
  --url "${BASE_URL}/devices" \
  --header 'accept: application/json' \
  --header "authorization: ${SESSION_API_KEY}" \
  --header 'content-type: application/json' \
  --get \
  --data-urlencode 'page_meta=true'
)
pretty_print_json 'Paging Devices' "${page_devices_result}"

# Query by Unique ID example
# see also https://dev.edgeiq.io/docs/api-overrview#query-string-operators
query_device_result=$(
  curl --silent --request GET \
  --url "${BASE_URL}/devices" \
  --header 'accept: application/json' \
  --header "authorization: ${SESSION_API_KEY}" \
  --header 'content-type: application/json' \
  --get \
  --data-urlencode "unique_id=${GATEWAY_UNIQUE_ID}"
)
pretty_print_json 'Query Device by Unique ID' "${query_device_result}"

# Query with tag "demo" example
# '_inc' suffix means field 'tags' is an array and query returns devices
#   who's 'tags' array contains an entry 'demo'
# see also https://dev.edgeiq.io/docs/api-overrview#query-string-operators
query_device_result=$(
  curl --silent --request GET \
  --url "${BASE_URL}/devices" \
  --header 'accept: application/json' \
  --header "authorization: ${SESSION_API_KEY}" \
  --header 'content-type: application/json' \
  --get \
  --data-urlencode 'tags_inc=demo'
)
pretty_print_json 'Query Device with tag "demo"' "${query_device_result}"

# Query Sensor reports
# see also https://dev.edgeiq.io/reference#get_reports
reports_result=$(
  curl --silent --request GET \
  --url "${BASE_URL}/reports" \
  --header 'accept: application/json' \
  --header "authorization: ${SESSION_API_KEY}" \
  --header 'content-type: application/json' \
  --get \
  --data-urlencode 'page_meta=true' \
  --data-urlencode "device_name=${GATEWAY_UNIQUE_ID}-sensor-1"
)
# Uncomment to see everything
# pretty_print_json 'Reports' "${query_device_result}"

printf "\nNumber of values returned: %s\n" "$(jq --raw-output '.total' <<<"${reports_result}")"

printf "\nLast Payload %s\n" "$(jq --color-output '.resources[0] | {device_datetime,payload}' <<<"${reports_result}")"
