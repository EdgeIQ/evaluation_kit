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

ssh-copy-id -f "${GATEWAY_USERNAME}@${GATEWAY_IP}"

# Put escrow token in the /opt/escrow_token file
# resolve ESCROW_TOKEN variable into string command to be run on remote gateway
ESCROW_TOKEN_COMMAND="sudo bash -c 'cat /dev/null > /opt/escrow_token && echo ${ESCROW_TOKEN} >> /opt/escrow_token'"

ssh -tq "${GATEWAY_USERNAME}@${GATEWAY_IP}" <<<"${ESCROW_TOKEN_COMMAND}"

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

ssh "${GATEWAY_USERNAME}@${GATEWAY_IP}" <<<"${EDGEIQ_INSTALL}"
