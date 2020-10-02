#!/usr/bin/env bash

# Assumes the following tools are installed
# * curl - tested against version 7.64.1
# * jq - tested against version 1.6 (https://stedolan.github.io/jq)
#
# This set of scripts performs the following:
# - Create two subaccounts under your account: "Demo Manufacturer" and "Demo Customer"
# - Create a User for each subaccount.
# - Provision gateway device & create token ID on device: /opt/escrow_token
# - Create Escrow Device on "Demo Manufacturer"
# - Issue Transfer Request to "Demo Customer" account
# - Accept Request in "Demo Customer" account
# - Create Device Type & Device in "Demo Manufacturer" account
# - Create Device Transfer Request on "Demo Manufacturer"
# - Get Device Transfer Request Status/Errors on "Demo Manufacturer"
# - Accept devices on "Demo Customer" subaccounts
# - Create Software Update & execute on device
#
#
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





# Call provision script
#
#
#printf "\n\nRunningf gateway_provision.sh script...\n\n"
#./gateway_provision.sh
#printf "\n\nLoading Escrow Token onto gateway device... May need to interactively enter sudo password.\n\n"
#ssh "${GATEWAY_USERNAME}@${GATEWAY_IP}" <<<"sudo touch /opt/escrow_token && sudo echo ${ESCROW_TOKEN} >> /opt/escrow_token"



# Collect enttity IDs only to make it easier to automate demo resources
declare -a TRANSLATOR_IDS
declare -a INGESTOR_IDS
declare -a DEVICE_TYPE_IDS
declare -a DEVICE_IDS
declare -a RULE_IDS
declare -a SOFTWARE_UPDATE_IDS
declare -a ESCROW_DEVICE_IDS
declare -a USER_IDS
declare -a COMPANY_IDS

validate_environment

SESSION_API_KEY=$(get_session_api_key)
MASTER_API_KEY=${SESSION_API_KEY}


# Get your current user & company id
#
# see also: https://dev.edgeiq.io/reference#get_users_bulk
my_company_result=$(
  curl --request GET \
    --url https://api.edgeiq.io/api/v1/platform/me \
    --header 'accept: application/json' \
    --header "authorization: ${SESSION_API_KEY}" \
    --header 'content-type: application/json'
)

MY_COMPANY_ID=$(jq --raw-output '.company_id' <<<"${my_company_result}")
MY_USER_ID=$(jq --raw-output '._id' <<<"${my_company_result}")


# Create Company Subaccounts - 1x Manufacturer
#
# see also https://dev.edgeiq.io/reference#post_devices
company_mfg_result=$(
  curl --silent --request POST \
    --url "${BASE_URL}/companies" \
    --header 'accept: application/json' \
    --header "authorization: ${SESSION_API_KEY}" \
    --header 'content-type: application/json' \
    --data @- <<EOF
{
  "name": "Demo Company - Manufacturer",
  "company_id": "${MY_COMPANY_ID}",
  "user_id": "${MY_USER_ID}"
}
EOF
)
pretty_print_json 'Company - Manufacturer' "${company_mfg_result}"

COMPANY_MFG_ID=$(jq --raw-output '._id' <<<"${company_mfg_result}")

COMPANY_IDS+=( "${COMPANY_MFG_ID}" )

# one more time, but for Cus acct
company_cus_result=$(
  curl --silent --request POST \
    --url "${BASE_URL}/companies" \
    --header 'accept: application/json' \
    --header "authorization: ${SESSION_API_KEY}" \
    --header 'content-type: application/json' \
    --data @- <<EOF
{
  "name": "Demo Company - Customer",
  "company_id": "${MY_COMPANY_ID}",
  "user_id": "${MY_USER_ID}"
}
EOF
)
pretty_print_json 'Company - Customer' "${company_cus_result}"

COMPANY_CUS_ID=$(jq --raw-output '._id' <<<"${company_cus_result}")

COMPANY_IDS+=( "${COMPANY_CUS_ID}" )


# Create users for subaccounts
#
#

# generate a random 4 digit code for email
random_id=$(< /dev/urandom LC_CTYPE=C tr -dc 0-9 | head -c${1:-6};echo;)

# Get the user types (Roles) & IDs so that we can assign users to Roles
user_types_result=$(
  curl --request GET \
    --url "${BASE_URL}/user_types" \
    --header 'accept: application/json' \
    --header "authorization: ${SESSION_API_KEY}" \
    --header 'content-type: application/json' \
)

USER_TYPE_ID=$(jq '.[] | select(.name == "system_admins") | ._id'  <<<"${user_types_result}")

user_mfg_pw=$(< /dev/urandom LC_CTYPE=C tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;)
printf "\n\nMFG Username: demo+evalkit_demomfguser${random_id}@edgeiq.io\n\nMFG password: ${user_mfg_pw}\n\n"

user_mfg_result=$(
  curl --silent --request POST \
    --url "${BASE_URL}/users" \
    --header 'accept: application/json' \
    --header "authorization: ${SESSION_API_KEY}" \
    --header 'content-type: application/json' \
    --data @- <<EOF
{
  "company_ids": [ "${COMPANY_MFG_ID}" ],
  "first_name": "Demo User - Manufacturer",
  "email": "demo+evalkit_demomfguser${random_id}@edgeiq.io",
  "password": "${user_mfg_pw}",
  "password_confirmation": "${user_mfg_pw}",
  "company_id": "${COMPANY_MFG_ID}",
  "user_type_id": ${USER_TYPE_ID}
}
EOF
)
pretty_print_json 'User - Manufacturer' "${user_mfg_result}"

USER_MFG_ID=$(jq --raw-output '._id' <<<"${user_mfg_result}")
USER_MFG_API_TOKEN=$(jq --raw-output '.api_token' <<<"${user_mfg_result}")

USER_IDS+=( "${USER_MFG_ID}" )

# now create the user for customer subaccount
user_cus_pw=$(< /dev/urandom LC_CTYPE=C tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;)
printf "\n\nCUS Username: demo+evalkit_democususer${random_id}@edgeiq.io\n\nCUS password: ${user_cus_pw}\n\n"

user_cus_result=$(
  curl --silent --request POST \
    --url "${BASE_URL}/users" \
    --header 'accept: application/json' \
    --header "authorization: ${SESSION_API_KEY}" \
    --header 'content-type: application/json' \
    --data @- <<EOF
{
  "company_ids": ["${COMPANY_CUS_ID}"],
  "first_name": "Demo User - Customer",
  "email": "demo+evalkit_democususer${random_id}@edgeiq.io",
  "password": "${user_cus_pw}",
  "password_confirmation": "${user_cus_pw}",
  "company_id": "${COMPANY_CUS_ID}",
  "user_type_id": ${USER_TYPE_ID}
}

EOF
)
pretty_print_json 'User - Customer' "${user_cus_result}"

USER_CUS_ID=$(jq --raw-output '._id' <<<"${user_cus_result}")
USER_CUS_API_TOKEN=$(jq --raw-output '.api_token' <<<${user_cus_result})
jq --raw-output '._api_token' <<<${user_cus_result}
USER_IDS+=( "${USER_CUS_ID}" )




# Switch to CUS user account to create Device Type
#
#
printf "\n\nSwitching to CUS user for API\n\n"
printf "${SESSION_API_KEY}\n\n"
#ADMIN_EMAIL="demo+evalkit_democususer${random_id}@edgeiq.io"
#demo+evalkit_demomfguser${random_id}@edgeiq.io
#ADMIN_PASSWORD=${user_mfg_pw}
SESSION_API_KEY=${USER_CUS_API_TOKEN}
#printf "${SESSION_API_KEY}\n\n"


# Create Gateway Device Type
# NOTE: a Device Type must be defined in the receiving account prior to issuing a transfer request
#
# see also https://dev.edgeiq.io/reference#post_device_types
gateway_device_type_result=$(
curl --silent --request POST \
  --url "${BASE_URL}/device_types" \
  --header 'accept: application/json' \
  --header "authorization: ${SESSION_API_KEY}" \
  --header 'content-type: application/json' \
  --data @- <<EOF
{
  "name": "Demo CUS Gateway Device Type",
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



# Switch to MFG user
#
#
printf "\n\nSwitching to MFG user for API\n\n"
#ADMIN_EMAIL="demo+evalkit_democususer${random_id}@edgeiq.io"
#demo+evalkit_demomfguser${random_id}@edgeiq.io
#ADMIN_PASSWORD=${user_mfg_pw}
SESSION_API_KEY=${USER_MFG_API_TOKEN}

# Create Escrow Device
#
#
escrow_device_result=$(
curl --silent --request POST \
  --url "${BASE_URL}/escrow_devices" \
  --header 'accept: application/json' \
  --header "authorization: ${SESSION_API_KEY}" \
  --header 'content-type: application/json' \
  --data @- <<EOF
{
  "unique_id": "${GATEWAY_UNIQUE_ID}",
  "token": "${ESCROW_TOKEN}",
  "device_type_id": "${GATEWAY_DEVICE_TYPE_ID}"
}
EOF
)
pretty_print_json 'Escrow Device' "${escrow_device_result}"

ESCROW_DEVICE_ID=$(jq --raw-output '._id' <<<"${escrow_device_result}")

ESCROW_DEVICES_IDS+=( "${ESCROW_DEVICE_ID}" )

# Create the Device Transfer Request
#
#see: https://dev.edgeiq.io/reference#device-transfer-requests
device_transfer_request_result=$(
curl --silent --request POST \
  --url "${BASE_URL}/device_transfer_requests" \
  --header 'accept: application/json' \
  --header "authorization: ${SESSION_API_KEY}" \
  --header 'content-type: application/json' \
  --data @- <<EOF
{
  "to_company_id": "${COMPANY_CUS_ID}",
  "escrow_device_ids": [ "${ESCROW_DEVICE_ID}" ],
  "device_type_id": "${GATEWAY_DEVICE_TYPE_ID}"
}
EOF
)
pretty_print_json 'Device Transfer Request' "${device_transfer_request_result}"

DEVICE_TRANSFER_REQUEST_ID=$(jq --raw-output '._id' <<<"${device_transfer_request_result}")

#DEVICE_TRANSFER_REQUEST_IDS+=( "${ESCROW_DEVICE_ID}" )



#DEVICE_TRANSFER_REQUEST_ID=$(jq --raw-output '._id' <<<"${initiate_transfer_result}")



#
# Switch to CUS user account to create Device Type
#
#
printf "\n\nSwitching to CUS user for API\n\n"
#ADMIN_EMAIL="demo+evalkit_democususer${random_id}@edgeiq.io"
#demo+evalkit_demomfguser${random_id}@edgeiq.io
#ADMIN_PASSWORD=${user_mfg_pw}
SESSION_API_KEY=${USER_CUS_API_TOKEN}

# Get your current user & company id
#
# see also: https://dev.edgeiq.io/reference#get_users_bulk
my_company_result=$(
  curl --request GET \
    --url https://api.edgeiq.io/api/v1/platform/me \
    --header 'accept: application/json' \
    --header "authorization: ${SESSION_API_KEY}"
)

MY_COMPANY_ID=$(jq --raw-output '.company_id' <<<"${my_company_result}")
MY_USER_ID=$(jq --raw-output '._id' <<<"${my_company_result}")


# Accept Transfer request
#
#
# Initiate the transfer request
#
# device_transfer_requests/5e3859ce66288000014f75f1/transfer
#see: https://dev.edgeiq.io/reference#post_device_transfer_request_transfer
initiate_transfer_result=$(
curl --silent --request POST \
  --url "${BASE_URL}/device_transfer_requests/${DEVICE_TRANSFER_REQUEST_ID}/transfer" \
  --header 'accept: application/json' \
  --header "authorization: ${SESSION_API_KEY}" \
  --header 'content-type: application/json' \
  --data @- <<EOF
{
  "unique_id": "${COMPANY_CUS_ID}",
  "to_company_id": [ "${ESCROW_DEVICE_ID}" ]
}
EOF
)
pretty_print_json 'Initiating the transfer request' "${initiate_transfer_result}"







# Create Software Update on CUS account to test/verify
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
  "name": "Demo Customer Software Update",
  "device_type_id": "${GATEWAY_DEVICE_TYPE_ID}",
  "script": "DATETIME1=`date`; logger \"edge: SOFTWARE UPDATE: Beginning update command at: \${DATETIME1}\"; apt update; apt upgrade -fmy; DATETIME2=`date`; logger \"edge: SOFTWARE UPDATE: Finished update command at: \${DATETIME2}\";"
}
EOF
)
pretty_print_json 'Software Update' "${software_update_result}"

SOFTWARE_UPDATE_ID=$(jq --raw-output '._id' <<<"${software_update_result}")

SOFTWARE_UPDATE_IDS+=( "${SOFTWARE_UPDATE_ID}" )




# Switch to Master user account
#
#
printf "\n\nSwitching to your Master account user for API\n\n"
#ADMIN_EMAIL="demo+evalkit_democususer${random_id}@edgeiq.io"
#demo+evalkit_demomfguser${random_id}@edgeiq.io
#ADMIN_PASSWORD=${user_mfg_pw}
SESSION_API_KEY=${MASTER_API_KEY}


# Create cleanup file

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
declare -ar _ESCROW_DEVICE_IDS=( ${ESCROW_DEVICE_IDS[@]} )
declare -ar _USER_IDS=( ${USER_IDS[@]} )
declare -ar _COMPANY_IDS=( ${COMPANY_IDS[@]} )


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
echo "Cleaning: Escrow Devices"
for id in "${_ESCROW_DEVICE_IDS[@]}"; do
  curl --request DELETE \
    --url "${BASE_URL}/escrow_devices/${id}" \
    --header 'accept: application/json' \
    --header "authorization: ${_SESSION_API_KEY}"
done
echo "Cleaning: Users"
for id in "${_USER_IDS[@]}"; do
  curl --request DELETE \
    --url "${BASE_URL}/users/${id}" \
    --header 'accept: application/json' \
    --header "authorization: ${_SESSION_API_KEY}"
done
echo "Cleaning: Companies"
for id in "${_COMPANY_IDS[@]}"; do
  curl --request DELETE \
    --url "${BASE_URL}/companies/${id}" \
    --header 'accept: application/json' \
    --header "authorization: ${_SESSION_API_KEY}"
done

rm -- "${FILE_NAME}"
EOF

chmod a+x "${FILE_NAME}"

sleep 2
printf "\n\n"
