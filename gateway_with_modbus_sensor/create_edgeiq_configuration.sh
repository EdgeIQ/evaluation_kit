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

# Collect entity IDs only to make it easier to automate demo resources
declare -a TRANSLATOR_IDS
declare -a INGESTOR_IDS
declare -a DEVICE_TYPE_IDS
declare -a DEVICE_IDS
declare -a RULE_IDS

validate_environment

SESSION_API_KEY=$(get_session_api_key)

# Create Modbus Translator
# valid type: template, javascript
# * template - use Go lang template processing with the following template variable
#   - output - raw data coming as string from ingestor protocol processing
#   - gateway_unique_id - unique device id of 'gateway' type device Ingestor is associated with
# see also https://dev.edgeiq.io/reference#post_translators
script_template=$(cat <<EOF
{
  "device_id": "{{.gateway_unique_id}}",
  "payload": {
    "type": "modbus sensor",
    "coil_status": {{.output}}
  }
}
EOF
)

# Using jq to JSON safe encode script_template and $(whoami) values
json_payload=$(
  jq --null-input \
    --arg name "Demo $(whoami)'s Modbus Translator" \
    --arg script "${script_template}" \
    '{ name: $name, type: "template", cloud_translator: false, script: $script }'
)

modbus_translator_result=$(
  curl --silent --request POST \
    --url "${BASE_URL}/translators" \
    --header 'accept: application/json' \
    --header "authorization: ${SESSION_API_KEY}" \
    --header 'content-type: application/json' \
    --data "${json_payload}"
)
pretty_print_json "Modbus Translator" "${modbus_translator_result}"

MODBUS_TRANSLATOR_ID=$(jq --raw-output '._id' <<<"${modbus_translator_result}")

TRANSLATOR_IDS+=( "${MODBUS_TRANSLATOR_ID}" )

# Create Modbus Ingestor
# see also https://dev.edgeiq.io/reference#post_ingestors
modbus_ingestor_result=$(
  curl --silent --request POST \
    --url "${BASE_URL}/ingestors" \
    --header 'accept: application/json' \
    --header "authorization: ${SESSION_API_KEY}" \
    --header 'content-type: application/json' \
    --data @- <<EOF
{
  "name": "Demo $(whoami)'s Modbus Ingestor",
  "cloud_translator": false,
  "listener_type": "tcp_modbus",
    "listener": {
      "host": "127.0.0.1",
      "params": {
        "address": "1",
        "and_mask": 0,
        "or_mask": 0,
        "quantity": 1,
        "request_type": "read_coils",
        "value": 0
      },
      "poll_interval": 5,
      "port": 502,
      "slave_id": 1,
      "timeout": 5
    },
    "handler_type": "passthrough",
    "translator_id": "${MODBUS_TRANSLATOR_ID}"
}
EOF
)
pretty_print_json "Modbus Ingestor" "${modbus_ingestor_result}"

MODBUS_INGESTOR_ID=$(jq --raw-output '._id' <<<"${modbus_ingestor_result}")

INGESTOR_IDS+=( "${MODBUS_INGESTOR_ID}" )

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
  "name": "Demo $(whoami)'s Gateway Device Type",
  "long_description": "",
  "manufacturer": "${GATEWAY_MANUFACTURER}",
  "model": "${GATEWAY_MODEL}",
  "type": "gateway",
  "ingestor_ids": [ "${MODBUS_INGESTOR_ID}" ],
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
  "name": "Demo $(whoami)'s Gateway",
  "device_type_id": "${GATEWAY_DEVICE_TYPE_ID}",
  "unique_id": "${GATEWAY_UNIQUE_ID}",
  "heartbeat_period": 120,
  "heartbeat_values": [ "cpu_usage" ],
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
  "description": "Demo $(whoami)'s Relay All to the Cloud",
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
printf "\nAssociate Relay Rule with Gateway Device Type\n"
curl --silent --request PUT \
  --url "${BASE_URL}/device_types/${GATEWAY_DEVICE_TYPE_ID}/rules/${RELAY_RULE_ID}" \
  --header 'accept: application/json' \
  --header "authorization: ${SESSION_API_KEY}" \
  --header 'content-type: application/json'

# Create HTTP forward rule
# see also https://dev.edgeiq.io/reference#post_rules
http_rule_result=$(
  curl --silent --request POST \
    --url "${BASE_URL}/rules" \
    --header 'accept: application/json' \
    --header "authorization: ${SESSION_API_KEY}" \
    --header 'content-type: application/json' \
    --data @- <<EOF
{
  "description": "Demo $(whoami)'s HTTP forward",
  "active": true,
  "cloud_rule": false,
  "then_actions": [
    {
      "type": "http_request",
      "send_to": "http://localhost:5005/",
      "body_template": "coil_status for {{.device.name}} is {{.report.payload.coil_status}}",
      "method": "put",
      "headers": { "Content-Type": "text/plain" }
    }
  ],
  "rule_condition": {
    "type": "equal",
    "property": "type",
    "value": "modbus sensor"
  }
}
EOF
)
pretty_print_json 'HTTP Rule' "${http_rule_result}"

HTTP_RULE_ID=$(jq --raw-output '._id' <<<"${http_rule_result}")

RULE_IDS+=( "${HTTP_RULE_ID}" )

# Associate HTTP Forward Rule with Gateway Device Type
# see also https://dev.edgeiq.io/reference#put_attach_rule_to_device_type
# Note: you can also associate Rules with individual Devices
printf "\nAssociate HTTP Rule with Gateway Device Type\n"
curl --silent --request PUT \
  --url "${BASE_URL}/device_types/${GATEWAY_DEVICE_TYPE_ID}/rules/${HTTP_RULE_ID}" \
  --header 'accept: application/json' \
  --header "authorization: ${SESSION_API_KEY}" \
  --header 'content-type: application/json'

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

declare -ar _DEVICE_IDS=( ${DEVICE_IDS[@]} )
declare -ar _DEVICE_TYPE_IDS=( ${DEVICE_TYPE_IDS[@]} )
declare -ar _TRANSLATOR_IDS=( ${TRANSLATOR_IDS[@]} )
declare -ar _INGESTOR_IDS=( ${INGESTOR_IDS[@]} )
declare -ar _RULE_IDS=( ${RULE_IDS[@]} )

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

for id in "${_DEVICE_IDS[@]}"; do
  curl --request DELETE \
    --url "${BASE_URL}/devices/${id}" \
    --header 'accept: application/json' \
    --header "authorization: ${_SESSION_API_KEY}"
done

for id in "${_DEVICE_TYPE_IDS[@]}"; do
  curl --request DELETE \
    --url "${BASE_URL}/device_types/${id}" \
    --header 'accept: application/json' \
    --header "authorization: ${_SESSION_API_KEY}"
done

for id in "${_INGESTOR_IDS[@]}"; do
  curl --request DELETE \
    --url "${BASE_URL}/ingestors/${id}" \
    --header 'accept: application/json' \
    --header "authorization: ${_SESSION_API_KEY}"
done

for id in "${_TRANSLATOR_IDS[@]}"; do
  curl --request DELETE \
    --url "${BASE_URL}/translators/${id}" \
    --header 'accept: application/json' \
    --header "authorization: ${_SESSION_API_KEY}"
done

for id in "${_RULE_IDS[@]}"; do
  curl --request DELETE \
    --url "${BASE_URL}/rules/${id}" \
    --header 'accept: application/json' \
    --header "authorization: ${_SESSION_API_KEY}"
done

rm -- "${FILE_NAME}"
EOF

chmod a+x "${FILE_NAME}"
