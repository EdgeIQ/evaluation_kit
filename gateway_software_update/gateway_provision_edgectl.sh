#!/usr/bin/env bash
#
# This script will check for apt, add the EdgeIQ repository,
# and install the edgeiq-edgectl package if available
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

# Install EdgeIQ SmartEdge service

EDGEIQ_INSTALL=$(cat <<EOF
echo "Adding EdgeIQ repository to apt sources... "
sudo echo "deb [trusted=yes] https://apt.fury.io/machineshop/ /" > /etc/apt/sources.list.d/fury.list
echo "Done."
echo "Here's what it looks like:"
sudo cat /etc/apt/sources.list.d/fury.list
echo "Running apt update... "
sudo apt update
echo "Done."
echo "Installing edgeiq-edgectl via apt... "
sudo apt install edgeiq-edgectl
echo -e "BLUE='\033[0;34m'Done."
EOF
)
ssh "${GATEWAY_USERNAME}@${GATEWAY_IP}" <<<"${EDGEIQ_INSTALL}"
