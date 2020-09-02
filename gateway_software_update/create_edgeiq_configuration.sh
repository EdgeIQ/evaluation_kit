#!/usr/bin/env bash

# This script will create a new gateway device type, device & software_update
# - get device ID
# - create software update config (simple apt-get update/upgrade/reboot)
# - execute gateway command to update software
#
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

# Create Gateway Device Type
# see also https://dev.edgeiq.io/reference#post_device_types
gateway_device_type_result=$(
curl --silent --request POST \
  --url "${BASE_URL}/device_types" \
  --header 'accept: application/json' \
  --header "authorization: ${SESSION_API_KEY}" \
  --header 'content-type: application/json' \
  --data @- <<EOF
{
  "name": "Demo $(whoami)'s Device Type",
  "long_description": "",
  "manufacturer": "${GATEWAY_MANUFACTURER}",
  "model": "${GATEWAY_MODEL}",
  "type": "gateway",
  "capabilities": {
    "network_connections": [
      { "type": "ethernet-wan", "name": "eth0" }
    ],
    "peripherals": [],
    "firmware": {
      "upgrade": false,
      "backup": false
    },
    "actions": {
      "notification": true,
      "send_config": true,
      "request_deployment_status": true,
      "update_edge": true,
      "update_firmware": true,
      "log_level": true,
      "log_config": true,
      "log_upload": true,
      "reboot": true,
      "heartbeat": true,
      "software_update": true,
      "greengrass_initialize": true,
      "greengrass_restart": true,
      "greengrass_redeploy": true,
      "log": true,
      "sms": false,
      "email": false,
      "relay": true,
      "http_request": true,
      "mqtt": false,
      "aws_iot": true,
      "tcp": false,
      "tcp_modbus": true,
      "opcua": false,
      "bacnet": false
    }
  }
}
EOF
)
pretty_print_json 'Device Type' "${gateway_device_type_result}"

GATEWAY_DEVICE_TYPE_ID=$(jq --raw-output '._id' <<<"${gateway_device_type_result}")

# Create Gateway Device
# valid log level values: trace, debug, info, warn, error, critical
# valid heartbeat_values: cell_signal, cell_usage, sim_card, connections, wifi_clients, cpu_usage, ram_usage, disk_size, disk_free, disk_usage, custom
# heartbeat_period is number of seconds
# see also https://dev.edgeiq.io/reference#post_devices
gateway_device_result=$(
  curl --silent --request POST \
    --url "${BASE_URL}/devices" \
    --header 'accept: application/json' \
    --header "authorization: ${SESSION_API_KEY}" \
    --header 'content-type: application/json' \
    --data @- <<EOF
{
  "name": "Demo $(whoami)'s Gateway",
  "device_type_id": "${GATEWAY_DEVICE_TYPE_ID}",
  "unique_id": "${GATEWAY_UNIQUE_ID}",
  "heartbeat_period": 120,
  "heartbeat_values": [ "cpu_usage" ],
  "ingestor_ids": [],
  "tags": [ "demo" ],
  "log_config": {
    "local_level": "error",
    "forward_level": "error",
    "forward_frequency_limit": 60
  }
}
EOF
)
pretty_print_json 'Device' "${gateway_device_result}"

GATEWAY_DEVICE_ID=$(jq --raw-output '._id' <<<"${gateway_device_result}")

# Create Software Update
# files: array of name/link combo for files to be downloaded to gateway and executed
# script: [command] | command or filename or script. i.e. "./install.sh"
# reboot: true, false | reboot after software update
# see also https://dev.edgeiq.io/reference#post_software_updates
software_update_result=$(
  curl --silent --request POST \
    --url "${BASE_URL}/software_updates" \
    --header 'accept: application/json' \
    --header "authorization: ${SESSION_API_KEY}" \
    --header 'content-type: multipart/form-data; boundary=---011000010111000001101001' \
    --data @- <<EOF
{
  "name": "Demo Software Update"
  "device_type_id": "${GATEWAY_DEVICE_TYPE_ID}",
  "files": NULL,
  "script": "apt-get update; apt-get upgrade -f -m -y;",
  "reboot": true,
}
EOF
)
pretty_print_json 'Device' "${software_update_result}"

SOFTWARE_UPDATE_ID=$(jq --raw-output '._id' <<<"${software_update_result}")

# Tell our gateway device to update it's config to see all these new changes
# see also https://dev.edgeiq.io/reference#devices-gateway-commands-1
printf "\nTelling the gateway to update it's configuration... Done.\n"
send_config_result=$(
  curl --silent --request POST \
    --url "${BASE_URL}/devices/${GATEWAY_DEVICE_ID}/send_config" \
    --header 'accept: application/json' \
    --header "authorization: ${SESSION_API_KEY}" \
    --header 'content-type: application/json'
)
pretty_print_json 'Send Config' "${send_config_result}"

# Create cleanup file

# Create cleanup script with unique name generated using num seconds since Jan 1 1970
FILE_NAME="cleanup-demo-$(date '+%s').sh"

# Expand environment variables
cat <<EOF >"${FILE_NAME}"
#!/usr/bin/env bash

_GATEWAY_DEVICE_ID="${GATEWAY_DEVICE_ID}"
_GATEWAY_DEVICE_TYPE_ID="${GATEWAY_DEVICE_TYPE_ID}"
_SOFTWARE_UPDATE_ID="${SOFTWARE_UPDATE_ID}"

FILE_NAME="${FILE_NAME}"
EOF

# Do NOT expand environment variables
cat <<'EOF' >>"${FILE_NAME}"

# Get directory this script is located in to access script local files
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

source "${_SCRIPT_DIR}/../setenv.sh"
source "${_SCRIPT_DIR}/../common_scripts.sh"

# Will exit script if we would use an uninitialised variable (nounset)
set -u
trap print_error ERR
trap "exit 1" TERM
export TOP_PID=$$

_SESSION_API_KEY=$(get_session_api_key)

curl --request DELETE \
  --url "${BASE_URL}/devices/${_GATEWAY_DEVICE_ID}" \
  --header 'accept: application/json' \
  --header "authorization: ${_SESSION_API_KEY}"

curl --request DELETE \
  --url "${BASE_URL}/device_types/${_GATEWAY_DEVICE_TYPE_ID}" \
  --header 'accept: application/json' \
  --header "authorization: ${_SESSION_API_KEY}"

curl --request DELETE \
    --url "${BASE_URL}/software_update/${_SOFTWARE_UPDATE_ID}" \
    --header 'accept: application/json' \
    --header "authorization: ${_SESSION_API_KEY}"

rm -- "${FILE_NAME}"
EOF

chmod a+x "${FILE_NAME}"
