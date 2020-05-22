#!/usr/bin/env bash

# Assumes the following tools are installed
# * curl - tested against version 7.64.1
# * jq - tested against version 1.6 (https://stedolan.github.io/jq)
# * HTTPie - tested against version 2.1.0 (https://httpie.org/)

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

if ! [[ -x "$(command -v http)" ]]; then
  echo 'HTTPie is required. Please install from https://httpie.org/ and try again.'
  exit 1
fi

if ! [[ -x "$(command -v jq)" ]]; then
  echo 'jq is required. Please install from https://stedolan.github.io/jq and try again.'
  exit 1
fi

# Get directory this script is located in to access script local files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

source "${SCRIPT_DIR}/setenv.sh"

# Get temporaray session token
SESSION_AUTH_RESULT=$(
  http --json --body POST "${BASE_URL}/user/authenticate" \
    "email=${ADMIN_EMAIL}" \
    "password=${ADMIN_PASSWORD}"
)

if [[ "${SESSION_AUTH_RESULT}" == *'Not authorized'* ]]; then
  printf "Invalid Credentials\n"
  exit
fi

SESSION_API_KEY=$(jq --raw-output '.session_token' <<<"${SESSION_AUTH_RESULT}")

# Create Modbus Translator
# valid type: template, javascript
# * template - use Go lang template processing with the following template variable
#   - output - raw data coming as string from ingestor protocol processing
# see also https://documentation.machineshop.io/api_docs/translators
MODBUS_TRANSLATOR_RESULT=$(
  http --json --body POST "${BASE_URL}/translators" \
    "Authorization:${SESSION_API_KEY}" <<EOF
{
  "name": "POC $(whoami)'s Modbus Translator",
  "type": "template",
  "cloud_translator": false,
  "script": "{\n\t\t\"device_id\": \"${GATEWAY_UNIQUE_ID}\",\n\t\t\"payload\": {\n\t\t\t\"coil_status\": {{.output}}\n\t\t}\n}"
}
EOF
)

printf "\nModbus Translator\n %s \n" "$(jq --color-output <<<"${MODBUS_TRANSLATOR_RESULT}")"

MODBUS_TRANSLATOR_ID=$(jq --raw-output '._id' <<<"${MODBUS_TRANSLATOR_RESULT}")

# Create Modbus Ingestor
# see also https://documentation.machineshop.io/api_docs/ingestors
MODBUS_INGESTOR_RESULT=$(
  http --json --body POST "${BASE_URL}/ingestors" \
    "Authorization:${SESSION_API_KEY}" <<EOF
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

printf "\nModbus Ingestor\n %s \n" "$(jq --color-output <<<"${MODBUS_INGESTOR_RESULT}")"

MODBUS_INGESTOR_ID=$(jq --raw-output '._id' <<<"${MODBUS_INGESTOR_RESULT}")

# Create Gateway Device Type
GATEWAY_DEVICE_TYPE_RESULT=$(
http --json --body POST "${BASE_URL}/device_types" \
    "Authorization:${SESSION_API_KEY}" <<EOF
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

printf "\nGateway Device Type\n %s \n" "$(jq --color-output <<<"${GATEWAY_DEVICE_TYPE_RESULT}")"

GATEWAY_DEVICE_TYPE_ID=$(jq --raw-output '._id' <<<"${GATEWAY_DEVICE_TYPE_RESULT}")

# Create Gateway Device
# valid log level values: trace, debug, info, warn, error, critical
# valid heartbeat_values: cell_signal, cell_usage, sim_card, connections, wifi_clients, cpu_usage, ram_usage, disk_size, disk_free, disk_usage, custom
# heartbeat_period is number of seconds
GATEWAY_DEVICE_RESULT=$(
  http --json --body POST "${BASE_URL}/devices" \
    "Authorization:${SESSION_API_KEY}" <<EOF
{
  "name": "POC $(whoami)'s Raspberry Pi Linux armv7+",
  "device_type_id": "${GATEWAY_DEVICE_TYPE_ID}",
  "unique_id": "${GATEWAY_UNIQUE_ID}",
  "heartbeat_period": 120,
  "heartbeat_values": [ "cpu_usage" ],
  "ingestor_ids": [ "${MODBUS_INGESTOR_ID}" ],
  "tags": [ "poc" ],
  "log_config": {
      "local_level": "error",
      "forward_level": "error",
      "forward_frequency_limit": 60
    }
}
EOF
)

printf "\nGateway Device\n %s \n" "$(jq --color-output <<<"${GATEWAY_DEVICE_RESULT}")"

GATEWAY_DEVICE_ID=$(jq --raw-output '._id' <<<"${GATEWAY_DEVICE_RESULT}")

# Create Relay Rule
# see also https://documentation.machineshop.io/api_docs/rules
RELAY_RULE_RESULT=$(
  http --json --body POST "${BASE_URL}/rules" \
    "Authorization:${SESSION_API_KEY}" <<EOF
{
  "description": "POC $(whoami)'s Relay All to the Cloud",
  "active": true,
  "cloud_rule": false,
  "then_actions": [ { "type": "relay" } ],
  "rule_condition": { "type": "true" }
}
EOF
)

printf "\nRelay Rule\n %s \n" "$(jq --color-output <<<"${RELAY_RULE_RESULT}")"

RELAY_RULE_ID=$(jq --raw-output '._id' <<<"${RELAY_RULE_RESULT}")

# Associate Rule with Gateway
printf "\nAssociate Relay Rule with Device\n"
http --json --print=Hh PUT "${BASE_URL}/devices/${GATEWAY_DEVICE_ID}/rules/${RELAY_RULE_ID}" \
  "Authorization:${SESSION_API_KEY}"

# Create HTTP forward rule
# see also https://documentation.machineshop.io/api_docs/rules
HTTP_RULE_RESULT=$(
  http --json --body POST "${BASE_URL}/rules" \
    "Authorization:${SESSION_API_KEY}" <<EOF
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

printf "\nHTTP Rule\n %s \n" "$(jq --color-output <<<"${HTTP_RULE_RESULT}")"

HTTP_RULE_ID=$(jq --raw-output '._id' <<<"${HTTP_RULE_RESULT}")

# Associate Rule with Gateway
printf "\nAssociate HTTP Rule with Device\n"
http --json --print=Hh PUT "${BASE_URL}/devices/${GATEWAY_DEVICE_ID}/rules/${HTTP_RULE_ID}" \
  "Authorization:${SESSION_API_KEY}"


# Create cleanup file

FILE_NAME="cleanup-poc-$(date --iso-8601='seconds').sh"
cat <<EOF >"${FILE_NAME}" 
#!/usr/bin/env bash

http --json --print=Hh DELETE "${BASE_URL}/devices/${GATEWAY_DEVICE_ID}" \
  "Authorization:${SESSION_API_KEY}"

http --json --print=Hh DELETE "${BASE_URL}/device_types/${GATEWAY_DEVICE_TYPE_ID}" \
  "Authorization:${SESSION_API_KEY}"

http --json --print=Hh DELETE "${BASE_URL}/ingestors/${MODBUS_INGESTOR_ID}" \
  "Authorization:${SESSION_API_KEY}"

http --json --print=Hh DELETE "${BASE_URL}/translators/${MODBUS_TRANSLATOR_ID}" \
  "Authorization:${SESSION_API_KEY}"

http --json --print=Hh DELETE "${BASE_URL}/rules/${RELAY_RULE_ID}" \
  "Authorization:${SESSION_API_KEY}"

http --json --print=Hh DELETE "${BASE_URL}/rules/${HTTP_RULE_ID}" \
  "Authorization:${SESSION_API_KEY}"

rm -- "${FILE_NAME}"
EOF

chmod a+x "${FILE_NAME}"
