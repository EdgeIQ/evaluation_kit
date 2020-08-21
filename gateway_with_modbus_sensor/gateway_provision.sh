#!/usr/bin/env bash

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

user_request=$(
  curl --silent --request GET \
    --url "${BASE_URL}/me" \
    --header 'accept: application/json' \
    --header "authorization: ${SESSION_API_KEY}" \
    --header 'content-type: application/json'
)
# pretty_print_json 'User' "${user_request}"

company_id=$(jq --raw-output '.company_id' <<<"${user_request}")

# clean up and then add known_hosts entries
ssh-keygen -R "${GATEWAY_IP}"

sleep 2

ssh-keyscan -H "${GATEWAY_IP}" >> ~/.ssh/known_hosts

ssh-copy-id -f "ubuntu@${GATEWAY_IP}"

# Update instance with Python 3 support to httpprint listener
ssh "$(whoami)@${GATEWAY_IP}" \
  "sudo sh -c 'apt-get update && apt-get upgrade --yes && apt-get install --yes python3 python3-pip'"

# copy files to device Instance
scp -r "${SCRIPT_DIR}/instance_files/"* \
  "$(whoami)@${GATEWAY_IP}:/home/ubuntu"

# install ModBus Server simulator
ssh "$(whoami)@${GATEWAY_IP}" \
  'sudo /bin/bash /home/ubuntu/diagslave_install.sh'

# Install EdgeIQ SmartEdge
EDGEIQ_INSTALL=$(cat <<EOF
wget --quiet --output-document='install.sh' \
  'https://api.edgeiq.io/api/v1/platform/installers/install.sh' \
  && sudo /bin/bash install.sh \
  --env 'prod' \
  --company ${company_id} \
  --make ${GATEWAY_MANUFACTURER} \
  --model ${GATEWAY_MODEL} \
  --url https://api.edgeiq.io/api/v1/platform/installers/${GATEWAY_MANUFACTURER}/${GATEWAY_MODEL}/edge-${SMARTEDGE_VERSION}.run
EOF
)

# printf "\nEIQ_INSTALL = %s\n" "${EDGEIQ_INSTALL}"

# shellcheck disable=SC2087
ssh "$(whoami)@${GATEWAY_IP}" <<<"${EDGEIQ_INSTALL}"

# install httpprint command
ssh "$(whoami)@${GATEWAY_IP}" \
  'sudo -H /bin/bash /home/ubuntu/httpprint_install.sh'
