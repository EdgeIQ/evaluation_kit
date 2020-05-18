#!/usr/bin/env bash

# Assumes the following tools are installed
# * curl - tested against version 7.64.1
# * jq - test against version 1.6 (https://stedolan.github.io/jq)

# Environment assumptions
# * Modbus sensor/simulator - running on ${MODBUS_SENSOR_IP} port 502 and read_coils slave 1 address 1
#   - tested against diagslave (https://www.modbusdriver.com/diagslave.html) `./linux_arm-eabigh/diagslave -m tcp`
# * HTTP Listener - running at ${HTTP_LISTENER_URL} to receive Modbus sensor reports
#   - example python HTTP listner included `httpprint.py`

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

# Create Modbus Translator
MODBUS_TRANSLATOR_RESULT=$(
  curl --silent --request POST \
    "${BASE_URL}/translators" \
    --header "Authorization: ${SESSION_API_KEY}" \
    --header 'Accept: application/json' \
    --data @- <<EOF
{
  "name": "POC $(whoami)'s Modbus Translator",
  "type": "template",
  "cloud_translator": false,
  "script": "{\n\t\t\"device_id\": \"${SENSOR_UNIQUE_ID}\",\n\t\t\"payload\": {\n\t\t\t\"coil_status\": {{.output}}\n\t\t}\n}"
}
EOF
)

printf "\nModbus Translator\n %s \n" "${MODBUS_TRANSLATOR_RESULT}"

MODBUS_TRANSLATOR_ID=$(jq --raw-output '._id' <<<"${MODBUS_TRANSLATOR_RESULT}")

# Create Modbus Ingestor
MODBUS_INGESTOR_RESULT=$(
  curl --silent --request POST \
    "${BASE_URL}/ingestors" \
    --header "Authorization: ${SESSION_API_KEY}" \
    --header 'Accept: application/json' \
    --data @- <<EOF
{
  "name": "POC $(whoami)'s Modbus Ingestor",
  "cloud_translator": false,
  "listener_type": "tcp_modbus",
    "listener": {
      "host": "${MODBUS_SENSOR_IP}",
      "params": {
        "address": "1",
        "and_mask": 0,
        "or_mask": 0,
        "quantity": 1,
        "request_type": "read_coils",
        "value": 0
      },
      "poll_interval": 5,
      "port": ${MODBUS_SENSOR_PORT},
      "slave_id": 1,
      "timeout": 5
    },
    "handler_type": "passthrough",
    "translator_id": "${MODBUS_TRANSLATOR_ID}"
}
EOF
)

printf "\nModbus Ingestor\n %s \n" "${MODBUS_INGESTOR_RESULT}"

MODBUS_INGESTOR_ID=$(jq --raw-output '._id' <<<"${MODBUS_INGESTOR_RESULT}")

# Create Sensor Device Type
SENSOR_DEVICE_TYPE_RESULT=$(
  curl --silent --request POST \
    "${BASE_URL}/device_types" \
    --header "Authorization: ${SESSION_API_KEY}" \
    --header 'Accept: application/json' \
    --data @- <<EOF
{
  "name": "POC $(whoami)'s Modbus Sensor",
  "long_description": "",
  "manufacturer": "machineshop",
  "model": "sensor",
  "type": "sensor"
}
EOF
)

printf "\nSensor Device Type\n %s \n" "${SENSOR_DEVICE_TYPE_RESULT}"

SENSOR_DEVICE_TYPE_ID=$(jq --raw-output '._id' <<<"${SENSOR_DEVICE_TYPE_RESULT}")

# Create Sensor Device
# valid log level values: trace, debug, info, warn, error, critical
SENSOR_DEVICE_RESULT=$(
  curl --silent --request POST \
    "${BASE_URL}/devices" \
    --header "Authorization: ${SESSION_API_KEY}" \
    --header 'Accept: application/json' \
    --data @- <<EOF
{
  "name": "POC $(whoami)'s Modbus Sensor",
  "device_type_id": "${SENSOR_DEVICE_TYPE_ID}",
  "unique_id": "${SENSOR_UNIQUE_ID}",
  "ingestor_ids": [ "${MODBUS_INGESTOR_ID}" ],
  "tags": [ "poc" ],
  "log_config": {
      "local_level": "debug",
      "forward_level": "error",
      "forward_frequency_limit": 60
    }
}
EOF
)

printf "\nSensor Device\n %s \n" "${SENSOR_DEVICE_RESULT}"

SENSOR_DEVICE_ID=$(jq --raw-output '._id' <<<"${SENSOR_DEVICE_RESULT}")

# Create Relay Rule
RELAY_RULE_RESULT=$(
  curl --silent --request POST \
    "${BASE_URL}/rules" \
    --header "Authorization: ${SESSION_API_KEY}" \
    --header 'Accept: application/json' \
    --data @- <<EOF
{
  "description": "POC $(whoami)'s Relay All to the Cloud",
  "active": true,
  "cloud_rule": false,
  "then_actions": [ { "type": "relay" } ],
  "rule_condition": { "type": "true" }
}
EOF
)

printf "\nRelay Rule\n %s \n" "${RELAY_RULE_RESULT}"

RELAY_RULE_ID=$(jq --raw-output '._id' <<<"${RELAY_RULE_RESULT}")

# Associate Rule with Sensor
curl --silent --request PUT \
  "${BASE_URL}/devices/${SENSOR_DEVICE_ID}/rules/${RELAY_RULE_ID}" \
  --header "Authorization: ${SESSION_API_KEY}" \
  --header 'Accept: application/json' \
  --write-out '\nRelay Rule Associate status %{http_code}\n'

# Create HTTP forward rule
HTTP_RULE_RESULT=$(
  curl --silent --request POST \
    "${BASE_URL}/rules" \
    --header "Authorization: ${SESSION_API_KEY}" \
    --header 'Accept: application/json' \
    --data @- <<EOF
{
  "description": "POC $(whoami)'s HTTP forward",
  "active": true,
  "cloud_rule": false,
  "then_actions": [
    {
      "type": "http_request",
      "send_to": "${HTTP_LISTENER_URL}",
      "body_template": "coil_status is {{.report.payload.coil_status}}",
      "method": "put",
      "headers": { "Content-Type": "text/plain" }
    }
  ],
  "rule_condition": { "type": "true" }
}
EOF
)

printf "\nHTTP Rule\n %s \n" "${HTTP_RULE_RESULT}"

HTTP_RULE_ID=$(jq --raw-output '._id' <<<"${HTTP_RULE_RESULT}")

# Associate Rule with Sensor
curl --silent --request PUT \
  "${BASE_URL}/devices/${SENSOR_DEVICE_ID}/rules/${HTTP_RULE_ID}" \
  --header "Authorization: ${SESSION_API_KEY}" \
  --header 'Accept: application/json' \
  --write-out '\nHTTP Rule Associate status %{http_code}\n'

# Create Gateway Device Type
GATEWAY_DEVICE_TYPE_RESULT=$(
  curl --silent --request POST \
    "${BASE_URL}/device_types" \
    --header "Authorization: ${SESSION_API_KEY}" \
    --header 'Accept: application/json' \
    --data @- <<EOF
{
  "name": "POC $(whoami)'s Raspberry Pi Linux armv7+",
  "long_description": "",
  "manufacturer": "rpf",
  "model": "rpi",
  "type": "gateway",
  "capabilities": {
    "network_connections": [
      { "type": "ethernet-wan", "name": "eth0" },
      { "type": "wifi", "name": "wlan0" }
    ]
  }
}
EOF
)

printf "\nGateway Device Type\n %s \n" "${GATEWAY_DEVICE_TYPE_RESULT}"

GATEWAY_DEVICE_TYPE_ID=$(jq --raw-output '._id' <<<"${GATEWAY_DEVICE_TYPE_RESULT}")

# Create Gateway Device
# valid log level values: trace, debug, info, warn, error, critical
# valid heartbeat_values: cell_signal, cell_usage, sim_card, connections, wifi_clients, cpu_usage, ram_usage, disk_size, disk_free, disk_usage, custom
# heartbeat_period is number of seconds
GATEWAY_DEVICE_RESULT=$(
  curl --silent --request POST \
    "${BASE_URL}/devices" \
    --header "Authorization: ${SESSION_API_KEY}" \
    --header 'Accept: application/json' \
    --data @- <<EOF
{
  "name": "POC $(whoami)'s Raspberry Pi Linux armv7+",
  "device_type_id": "${GATEWAY_DEVICE_TYPE_ID}",
  "unique_id": "${GATEWAY_UNIQUE_ID}",
  "heartbeat_period": 120,
  "heartbeat_values": [ "cpu_usage" ],
  "attached_device_ids": [ "${SENSOR_DEVICE_ID}" ],
  "tags": [ "poc" ],
  "log_config": {
      "local_level": "debug",
      "forward_level": "error",
      "forward_frequency_limit": 60
    }
}
EOF
)

printf "\nGateway Device\n %s \n" "${GATEWAY_DEVICE_RESULT}"

GATEWAY_DEVICE_ID=$(jq --raw-output '._id' <<<"${GATEWAY_DEVICE_RESULT}")

# Create cleanup file

FILE_NAME="cleanup-poc-$(date --iso-8601='seconds').sh"
cat <<EOF >"${FILE_NAME}" 
#!/usr/bin/env bash

curl --silent --request DELETE \
  "${BASE_URL}/devices/${SENSOR_DEVICE_ID}" \
  --header "Authorization: ${SESSION_API_KEY}" \
  --header 'Accept: application/json' \
  --write-out '\nDelete Sensor Device status %{http_code}\n'

curl --silent --request DELETE \
  "${BASE_URL}/device_types/${SENSOR_DEVICE_TYPE_ID}" \
  --header "Authorization: ${SESSION_API_KEY}" \
  --header 'Accept: application/json' \
  --write-out '\nDelete Sensor Device Type status %{http_code}\n'

curl --silent --request DELETE \
  "${BASE_URL}/devices/${GATEWAY_DEVICE_ID}" \
  --header "Authorization: ${SESSION_API_KEY}" \
  --header 'Accept: application/json' \
  --write-out '\nDelete Gateway Device status %{http_code}\n'

curl --silent --request DELETE \
  "${BASE_URL}/device_types/${GATEWAY_DEVICE_TYPE_ID}" \
  --header "Authorization: ${SESSION_API_KEY}" \
  --header 'Accept: application/json' \
  --write-out '\nDelete Gateway Device Type status %{http_code}\n'

curl --silent --request DELETE \
  "${BASE_URL}/ingestors/${MODBUS_INGESTOR_ID}" \
  --header "Authorization: ${SESSION_API_KEY}" \
  --header 'Accept: application/json' \
  --write-out '\nDelete Modbus Ingestor status %{http_code}\n'

curl --silent --request DELETE \
  "${BASE_URL}/translators/${MODBUS_TRANSLATOR_ID}" \
  --header "Authorization: ${SESSION_API_KEY}" \
  --header 'Accept: application/json' \
  --write-out '\nDelete Modbus Translator status %{http_code}\n'

curl --silent --request DELETE \
  "${BASE_URL}/rules/${RELAY_RULE_ID}" \
  --header "Authorization: ${SESSION_API_KEY}" \
  --header 'Accept: application/json' \
  --write-out '\nDelete Relay Rule status %{http_code}\n'

curl --silent --request DELETE \
  "${BASE_URL}/rules/${HTTP_RULE_ID}" \
  --header "Authorization: ${SESSION_API_KEY}" \
  --header 'Accept: application/json' \
  --write-out '\nDelete HTTP Rule status %{http_code}\n'

rm -- "${FILE_NAME}"
EOF

chmod a+x "${FILE_NAME}"
