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

# Collect enttity IDs only to make it easier to automate demo resources
declare -a TRANSLATOR_IDS
declare -a INGESTOR_IDS
declare -a DEVICE_TYPE_IDS
declare -a DEVICE_IDS
declare -a RULE_IDS
declare -a SOFTWARE_UPDATE_IDS

validate_environment

SESSION_API_KEY=$(get_session_api_key)

# Create Sensor Device Type
# see also https://dev.edgeiq.io/reference#post_device_types
sensor_device_type_result=$(
curl --silent --request POST \
  --url "${BASE_URL}/device_types" \
  --header 'accept: application/json' \
  --header "authorization: ${SESSION_API_KEY}" \
  --header 'content-type: application/json' \
  --data @- <<EOF
{
  "name": "Demo Sensor Device Type",
  "long_description": "",
  "manufacturer": "generic",
  "model": "sensor",
  "type": "sensor",
  "ingestor_ids": [],
  "capabilities": {
    "actions": {
      "notification": true,
      "send_config": true,
      "request_deployment_status": true,
      "update_edge": true,
      "log_level": true,
      "log_config": true,
      "log_upload": true,
      "heartbeat": true,
      "software_update": true,
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
pretty_print_json 'Sensor Device Type' "${sensor_device_type_result}"

SENSOR_DEVICE_TYPE_ID=$(jq --raw-output '._id' <<<"${sensor_device_type_result}")

DEVICE_TYPE_IDS+=( "${SENSOR_DEVICE_TYPE_ID}" )

# Create Sensor Device
# valid log level values: trace, debug, info, warn, error, critical
# valid heartbeat_values: cell_signal, cell_usage, sim_card, connections, wifi_clients, cpu_usage, ram_usage, disk_size, disk_free, disk_usage, custom
# heartbeat_period is number of seconds
# see also https://dev.edgeiq.io/reference#post_devices
sensor_device_result=$(
  curl --silent --request POST \
    --url "${BASE_URL}/devices" \
    --header 'accept: application/json' \
    --header "authorization: ${SESSION_API_KEY}" \
    --header 'content-type: application/json' \
    --data @- <<EOF
{
  "name": "Demo Sensor",
  "device_type_id": "${SENSOR_DEVICE_TYPE_ID}",
  "unique_id": "${GATEWAY_UNIQUE_ID}-sensor-1",
  "heartbeat_period": 120,
  "heartbeat_values": [],
  "ingestor_ids": [],
  "attached_device_ids": [],
  "tags": [ "demo" ],
  "log_config": {
    "local_level": "error",
    "forward_level": "error",
    "forward_frequency_limit": 60
  }
}
EOF
)
pretty_print_json 'Sensor Device' "${sensor_device_result}"

SENSOR_DEVICE_ID=$(jq --raw-output '._id' <<<"${sensor_device_result}")

DEVICE_IDS+=( "${SENSOR_DEVICE_ID}" )


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
  "name": "Demo Gateway Device Type",
  "long_description": "",
  "manufacturer": "${GATEWAY_MANUFACTURER}",
  "model": "${GATEWAY_MODEL}",
  "type": "gateway",
  "ingestor_ids": [],
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
pretty_print_json 'Gateway Device Type' "${gateway_device_type_result}"

GATEWAY_DEVICE_TYPE_ID=$(jq --raw-output '._id' <<<"${gateway_device_type_result}")

DEVICE_TYPE_IDS+=( "${GATEWAY_DEVICE_TYPE_ID}" )

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
  "name": "Demo Gateway",
  "device_type_id": "${GATEWAY_DEVICE_TYPE_ID}",
  "unique_id": "${GATEWAY_UNIQUE_ID}",
  "heartbeat_period": 60,
  "heartbeat_values": [ "cpu_usage", "disk_usage", "ram_usage" ],
  "ingestor_ids": [],
  "attached_device_ids": [ "${SENSOR_DEVICE_ID}" ],
  "tags": [ "demo" ],
  "log_config": {
    "local_level": "error",
    "forward_level": "error",
    "forward_frequency_limit": 60
  }
}
EOF
)
pretty_print_json 'Gateway Device' "${gateway_device_result}"

GATEWAY_DEVICE_ID=$(jq --raw-output '._id' <<<"${gateway_device_result}")

DEVICE_IDS+=( "${GATEWAY_DEVICE_ID}" )

# Create Relay Rule to forward all reports to EdgeIQ cloud
# see also https://dev.edgeiq.io/reference#post_rules
relay_rule_result=$(
  curl --silent --request POST \
    --url "${BASE_URL}/rules" \
    --header 'accept: application/json' \
    --header "authorization: ${SESSION_API_KEY}" \
    --header 'content-type: application/json' \
    --data @- <<EOF
{
  "description": "Demo Relay All to the Cloud",
  "active": true,
  "cloud_rule": false,
  "then_actions": [ { "type": "relay" } ],
  "rule_condition": { "type": "true" }
}
EOF
)
pretty_print_json 'Relay Rule' "${relay_rule_result}"

RELAY_RULE_ID=$(jq --raw-output '._id' <<<"${relay_rule_result}")

RULE_IDS+=( "${RELAY_RULE_ID}" )

# Associate Relay Rule
# see also https://dev.edgeiq.io/reference#put_attach_rule_to_device_type
# Note: you can also associate Rules with individual Devices
printf "\nAssociate Relay Rule with Sensor Device Type\n"
curl --silent --request PUT \
  --url "${BASE_URL}/device_types/${SENSOR_DEVICE_TYPE_ID}/rules/${RELAY_RULE_ID}" \
  --header 'accept: application/json' \
  --header "authorization: ${SESSION_API_KEY}" \
  --header 'content-type: application/json'

printf "\nAssociate Relay Rule with Gateway Device Type\n"
curl --silent --request PUT \
  --url "${BASE_URL}/device_types/${GATEWAY_DEVICE_TYPE_ID}/rules/${RELAY_RULE_ID}" \
  --header 'accept: application/json' \
  --header "authorization: ${SESSION_API_KEY}" \
  --header 'content-type: application/json'



# Create Software Update
# files: array of name/link combo for files to be downloaded to gateway and executed
# script: [command] | command or filename or script. i.e. "./install.sh"
# reboot: true, false | reboot after software update
# see also https://dev.edgeiq.io/reference#post_software_updates
software_update_result=$(
  curl --silent --request POST \
    --url "${BASE_URL}/software_updates" \
    --header "accept: application/json" \
    --header "authorization: ${SESSION_API_KEY}" \
    --header 'content-type: multipart/form-data; boundary=---011000010111000001101001' \
    --data @- <<EOF
{
  "name": "Demo Software Update",
  "device_type_id": "${GATEWAY_DEVICE_TYPE_ID}",
  "script": "apt update; apt upgrade -f -m -y;"
}
EOF
)
pretty_print_json 'Software Update' "${software_update_result}"

SOFTWARE_UPDATE_ID=$(jq --raw-output '._id' <<<"${software_update_result}")

SOFTWARE_UPDATE_IDS+=( "${SOFTWARE_UPDATE_ID}" )




# Tell our gateway device to update it's config to see all these new changes
# see also https://dev.edgeiq.io/reference#devices-gateway-commands-1
printf "\nTelling the gateway to update it's configuration... Done.\n"
curl --silent --request POST \
  --url "https://api.edgeiq.io/api/v1/platform/devices/${GATEWAY_DEVICE_ID}/send_config" \
  --header 'accept: application/json' \
  --header "authorization: ${SESSION_API_KEY}" \
  --header 'content-type: application/json'

# Create cleanup file
# Create cleanup script with unique name generated using num seconds since Jan 1 1970
FILE_NAME="cleanup-demo-$(date '+%s').sh"

# Expand environment variables
cat <<EOF >"${FILE_NAME}"
#!/usr/bin/env bash

declare -ar _DEVICE_IDS=( ${DEVICE_IDS[@]} )
declare -ar _DEVICE_TYPE_IDS=( ${DEVICE_TYPE_IDS[@]} )
declare -ar _TRANSLATOR_IDS=( ${TRANSLATOR_IDS[@]} )
declare -ar _INGESTOR_IDS=( ${INGESTOR_IDS[@]} )
declare -ar _RULE_IDS=( ${RULE_IDS[@]} )
declare -ar _SOFTWARE_UPDATE_IDS=( ${SOFTWARE_UPDATE_IDS[@]} )

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
echo "Cleaning: Devices"
for id in "${_DEVICE_IDS[@]}"; do
  curl --request DELETE \
    --url "${BASE_URL}/devices/${id}" \
    --header 'accept: application/json' \
    --header "authorization: ${_SESSION_API_KEY}"
done
echo "Cleaning: Device Types"
for id in "${_DEVICE_TYPE_IDS[@]}"; do
  curl --request DELETE \
    --url "${BASE_URL}/device_types/${id}" \
    --header 'accept: application/json' \
    --header "authorization: ${_SESSION_API_KEY}"
done
echo "Cleaning: Ingestors"
for id in "${_INGESTOR_IDS[@]}"; do
  curl --request DELETE \
    --url "${BASE_URL}/ingestors/${id}" \
    --header 'accept: application/json' \
    --header "authorization: ${_SESSION_API_KEY}"
done
echo "Cleaning: Translators"
for id in "${_TRANSLATOR_IDS[@]}"; do
  curl --request DELETE \
    --url "${BASE_URL}/translators/${id}" \
    --header 'accept: application/json' \
    --header "authorization: ${_SESSION_API_KEY}"
done
echo "Cleaning: Rules"
for id in "${_RULE_IDS[@]}"; do
  curl --request DELETE \
    --url "${BASE_URL}/rules/${id}" \
    --header 'accept: application/json' \
    --header "authorization: ${_SESSION_API_KEY}"
done
echo "Cleaning: Software Updates"
for id in "${_SOFTWARE_UPDATE_IDS[@]}"; do
  curl --request DELETE \
    --url "${BASE_URL}/software_updates/${id}" \
    --header 'accept: application/json' \
    --header "authorization: ${_SESSION_API_KEY}"
done

rm -- "${FILE_NAME}"
EOF

chmod a+x "${FILE_NAME}"

sleep 2
printf "\n\n"
read -n1 -rsp "Press any key to issue Software Update command via API..." key

if [ "$key" = '' ]; then
    printf "\nHold onto your butts...\n"
    gateway_command_result=$(
    curl --silent --request POST \
      --url "${BASE_URL}/devices/${GATEWAY_DEVICE_ID}/gateway_commands" \
      --header "accept: application/json" \
      --header "authorization: ${SESSION_API_KEY}" \
      --header "content-type: application/json" \
      --data @- <<EOF
{
"command_type": "software_update",
"software_update_id": "${SOFTWARE_UPDATE_ID}"
}
EOF
    )

    pretty_print_json 'Executing Software Update' "${gateway_command_result}"
    SOFTWARE_UPDATE_ID=$(jq --raw-output '._id' <<<"${software_update_result}")
    echo "Software Update executed."
else
    # Anything else pressed, do whatever else.
    printf "\nWrong key...\n"
fi
