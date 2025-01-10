#!/bin/bash
# Configure Solace PubSub Broker for KEDA Test

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SOLACE_HOST="http://kedalab-pubsubplus-dev:8080"
VPN_NAME="keda_vpn"
## admin:admin
## HDR_AUTH="Authorization: Basic YWRtaW46YWRtaW4="
#ADMIN_USER="admin"
#ADMIN_PWD="KedaLabAdminPwd1"
HDR_CONTENT_TYPE="Content-Type: application/json"

SEMP_BASE_URL="${SOLACE_HOST}/SEMP/v2/config/msgVpns"
SEMP_URL_CREATE_VPN="$SEMP_BASE_URL"
SEMP_URL_CREATE_CLIENT_PROFILE="${SEMP_BASE_URL}/${VPN_NAME}/clientProfiles"
SEMP_URL_CREATE_CLIENT_USER="${SEMP_BASE_URL}/${VPN_NAME}/clientUsernames"
SEMP_URL_CREATE_Q="${SEMP_BASE_URL}/${VPN_NAME}/queues"

CREATE_VPN_FILE="${SCRIPT_DIR}/create_vpn.json"
CREATE_CLIENT_PROFILE_FILE="${SCRIPT_DIR}/create_client_profile.json"
CREATE_CLIENT_USER_FILE="${SCRIPT_DIR}/create_client_user.json"
CREATE_Q1_FILE="${SCRIPT_DIR}/create_queue1.json"
CREATE_Q2_FILE="${SCRIPT_DIR}/create_queue2.json"

for arg in "$@"
do
  if [[ $arg =~ ^--help ]]; then
    _CONF_HELP="true"
  fi
  if [[ $arg =~ ^-h ]]; then
    _CONF_HELP="true"
  fi
  if [[ $arg =~ ^help ]]; then
    _CONF_HELP="true"
  fi
  echo $CONF_HELP
  if [ "$_CONF_HELP" = "true" ]; then
    echo "config_solace.sh -- Used to configure Solace PubSub broker for Keda Code Lab"
    echo "  Arguments:"
    echo "  --solace-host=Host URL        -- default: http://localhost:8080"
    echo "  --admin-user=SEMP User Id     -- default: admin"
    echo "  --admin-pwd=SEMP Password     -- default: admin"
    exit 0
  fi
done

for arg in "$@"
do
  if [[ $arg =~ ^--solace-host= ]]; then
    SOLACE_HOST=$(echo $arg | sed "s/--solace-host=//")
    continue
  fi
  if [[ $arg =~ ^--admin-user= ]]; then
    ADMIN_USER=$(echo $arg | sed "s/--admin-user=//")
    continue
  fi
  if [[ $arg =~ ^--admin-pwd= ]]; then
    ADMIN_PWD=$(echo $arg | sed "s/--admin-pwd=//")
    continue
  fi
done

## echo $SOLACE_HOST
## echo $ADMIN_USER
## echo $ADMIN_PWD

SEMP_BASE_URL="${SOLACE_HOST}/SEMP/v2/config/msgVpns"
SEMP_URL_CREATE_VPN="$SEMP_BASE_URL"
SEMP_URL_CREATE_CLIENT_PROFILE="${SEMP_BASE_URL}/${VPN_NAME}/clientProfiles"
SEMP_URL_CREATE_CLIENT_USER="${SEMP_BASE_URL}/${VPN_NAME}/clientUsernames"
SEMP_URL_CREATE_Q="${SEMP_BASE_URL}/${VPN_NAME}/queues"

HDR_AUTH=$(echo -ne "${ADMIN_USER}:${ADMIN_PWD}" | base64 )
HDR_AUTH="Authorization: Basic ${HDR_AUTH}"

## echo $HDR_AUTH
## echo $SEMP_BASE_URL
## echo $SEMP_URL_CREATE_VPN
## echo $SEMP_URL_CREATE_CLIENT_PROFILE
## echo $SEMP_URL_CREATE_CLIENT_USER
## echo $SEMP_URL_CREATE_Q

check_already_exists () {
    if [[ ! "$1" =~ "ALREADY_EXISTS" ]]; then
        echo "Create $3 failed"
        exit $2
    fi
}

check_response () {
  case $1 in
    200)
      ;;
    400)
      check_already_exists "$2" $3 "$4"
      echo "$4 already exists"
      ;;
    *)
        echo "Create $4 failed"
        exit $3
      ;;
  esac
}

success=$(curl -s -X POST -i -w "%{http_code}" -H "${HDR_CONTENT_TYPE}" -H "${HDR_AUTH}" --data @${CREATE_VPN_FILE} ${SEMP_URL_CREATE_VPN})
http_code=${success: -3}
check_response $http_code "$success" -10 "msgVpn"

success=$(curl -s -X POST -w "%{http_code}" -i -H "${HDR_CONTENT_TYPE}" -H "${HDR_AUTH}" --data @${CREATE_CLIENT_PROFILE_FILE} ${SEMP_URL_CREATE_CLIENT_PROFILE})
http_code=${success: -3}
check_response $http_code "$success" -20 "clientProfile"

success=$(curl -s -X POST -w "%{http_code}" -i -H "${HDR_CONTENT_TYPE}" -H "${HDR_AUTH}" --data @${CREATE_CLIENT_USER_FILE} ${SEMP_URL_CREATE_CLIENT_USER})
http_code=${success: -3}
check_response $http_code "$success" -30 "clientUser"

success=$(curl -s -X POST -w "%{http_code}" -i -H "${HDR_CONTENT_TYPE}" -H "${HDR_AUTH}" --data @${CREATE_Q1_FILE} ${SEMP_URL_CREATE_Q})
http_code=${success: -3}
check_response $http_code "$success" -40 "queue1"

success=$(curl -s -X POST -w "%{http_code}" -i -H "${HDR_CONTENT_TYPE}" -H "${HDR_AUTH}" --data @${CREATE_Q2_FILE} ${SEMP_URL_CREATE_Q})
http_code=${success: -3}
check_response $http_code "$success" -50 "queue2"

echo "Success!"
exit 0
