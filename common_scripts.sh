#!/usr/bin/env bash

# Get directory this script is located in to access script local files
readonly __SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

source "${__SCRIPT_DIR}/setenv.sh"

# Prints out line number of script errors. for use with trap
function print_error() {
  read -r line file <<<"$(caller)"
  echo "An error occurred in line ${line} of file ${file}:" >&2
  sed "${line}q;d" "${file}" >&2
}

# Validates that dependent tooling needed to run scripts is installed
function validate_environment() {
  if ! [[ -x "$(command -v curl)" ]]; then
    echo 'curl is required.'
    exit 1
  fi

  if ! [[ -x "$(command -v jq)" ]]; then
    echo 'jq is required. Please install from https://stedolan.github.io/jq and try again.'
    exit 1
  fi
}

function pretty_print_json() {
  local description=$1
  local json=$2

  printf "\n%s\n%s\n" "${description}" "$(jq --color-output <<<"${json}")"
}

function json_to_bash_array() {
  local json_array=$1

  jq --raw-output '.[]' <<<"${json_array}"
}

function bash_array_to_json_array() {
  local -n data=$1
  printf '%s\n' "${data[@]}" | jq --raw-input '.' | jq --slurp --compact-output '.'
}

function comma_separated_bash_array() {
  local -n data=$1
  printf -v var '%s,' "${data[@]}"
  echo "${var%,}"
}

# Gets temporary session token
function get_session_api_key() {
  # Get temporaray session token
  # see also https://dev.edgeiq.io/reference#post-user-authenticate
  local -r session_auth_result=$(
    curl --silent --request POST \
    --url "${BASE_URL}/user/authenticate" \
    --header 'accept: application/json' \
    --header 'content-type: application/json' \
    --data @- <<EOF
{
  "email": "${ADMIN_EMAIL}",
  "password": "${ADMIN_PASSWORD}"
}
EOF
  )

  if [[ "${session_auth_result}" == *'Not authorized'* ]]; then
    printf "Invalid Credentials\n" 1>&2
    kill -s TERM "${TOP_PID}"
  fi

  jq --raw-output '.session_token' <<<"${session_auth_result}"
}
