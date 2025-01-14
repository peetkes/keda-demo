#!/bin/bash
# Configure Solace PubSub Broker for KEDA Test

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SOLACE_HOST="http://kedalab-pubsubplus-dev:8080"
#VPN_NAME="keda_vpn"
VPN_NAME="default"
HDR_CONTENT_TYPE="Content-Type: application/json"
SUBSCRIPTION_QUEUE="pq12"
SEMP_BASE_URL="${SOLACE_HOST}/SEMP/v2/config"
SEMP_URL_VPNS="${SEMP_BASE_URL}/msgVpns"
SEMP_URL_CREATE_VPN="$SEMP_URL_VPNS"
SEMP_URL_PATCH_VPN="${SEMP_URL_VPNS}/${VPN_NAME}"
SEMP_URL_CREATE_CLIENT_PROFILE="${SEMP_URL_VPNS}/${VPN_NAME}/clientProfiles"
SEMP_URL_CREATE_CLIENT_USER="${SEMP_URL_VPNS}/${VPN_NAME}/clientUsernames"
SEMP_URL_CREATE_Q="${SEMP_URL_VPNS}/${VPN_NAME}/queues"
SEMP_URL_CREATE_Q_SUBSCRIPTION="${SEMP_URL_VPNS}/${VPN_NAME}/queues/${SUBSCRIPTION_QUEUE}/subscriptions"

PATCH_SERVICE_FILE="${SCRIPT_DIR}/patch_service.json"
CREATE_VPN_FILE="${SCRIPT_DIR}/create_vpn.json"
PATCH_VPN_FILE="${SCRIPT_DIR}/patch_vpn.json"
CREATE_CLIENT_PROFILE_FILE="${SCRIPT_DIR}/create_client_profile.json"
CREATE_CLIENT_USER_FILE="${SCRIPT_DIR}/create_client_user.json"
CREATE_Q1_FILE="${SCRIPT_DIR}/create_queue1.json"
CREATE_Q2_FILE="${SCRIPT_DIR}/create_queue2.json"
CREATE_PQ12_FILE="${SCRIPT_DIR}/create_pq12.json"
CREATE_PQ12_SUBSCRIPTION_FILE="${SCRIPT_DIR}/create_queue_subscription.json"

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

success=$(curl -s -X PATCH -i -w "%{http_code}" -H "${HDR_CONTENT_TYPE}" -H "${HDR_AUTH}" --data @${PATCH_SERVICE_FILE} ${SEMP_BASE_URL})
http_code=${success: -3}
check_response $http_code "$success" -10 "service"

#success=$(curl -s -X POST -i -w "%{http_code}" -H "${HDR_CONTENT_TYPE}" -H "${HDR_AUTH}" --data @${CREATE_VPN_FILE} ${SEMP_URL_CREATE_VPN})
#http_code=${success: -3}
#check_response $http_code "$success" -10 "msgVpn"

success=$(curl -s -X PATCH -i -w "%{http_code}" -H "${HDR_CONTENT_TYPE}" -H "${HDR_AUTH}" --data @${PATCH_VPN_FILE} ${SEMP_URL_PATCH_VPN})
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

success=$(curl -s -X POST -w "%{http_code}" -i -H "${HDR_CONTENT_TYPE}" -H "${HDR_AUTH}" --data @${CREATE_PQ12_FILE} ${SEMP_URL_CREATE_Q})
http_code=${success: -3}
check_response $http_code "$success" -50 "pq12"

success=$(curl -s -X POST -w "%{http_code}" -i -H "${HDR_CONTENT_TYPE}" -H "${HDR_AUTH}" --data @${CREATE_PQ12_SUBSCRIPTION_FILE} ${SEMP_URL_CREATE_Q_SUBSCRIPTION})
http_code=${success: -3}
check_response $http_code "$success" -50 "pq12 subscription"

echo "Success!"
exit 0
