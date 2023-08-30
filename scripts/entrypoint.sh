#!/usr/bin/env bash
set -e

#
# Validation for required variables
#

if [[ -z "$FQDN" ]]; then
  echo "FQDN environmental variable is required"
  exit 1
fi
if [[ -z "$HTTP_PROXY_URL" ]]; then
  echo "HTTP_PROXY_URL environmental variable is required"
  exit 1
fi
if [[ -z "$NX_PROXY_BUFFER_NUMBER" ]]; then
  echo "NX_PROXY_BUFFER_NUMBER environmental variable is required (nginx proxy_buffers setting)"
  exit 1
fi
if [[ -z "$NX_PROXY_BUFFER_SIZE" ]]; then
  echo "NX_PROXY_BUFFER_SIZE environmental variable is required (nginx proxy_buffers setting)"
  exit 1
fi
if [[ -z ${SUBPATH} ]]; then
  echo "SUBPATH environmental variable being set to blank"
  export SUBPATH=""
fi

#
# Optional variables
#

# SERVER_NAME should be optional but needs to be a string, even if empty.
: "${SERVER_NAME:=}"
export SERVER_NAME

# ENABLE_RATE_LIMITING enables (uncomments) the rate limiting section of the config file.
if [[ "$(echo $ENABLE_RATE_LIMITING | tr '[:upper:]' '[:lower:]')" == "true" ]]; then
  RATE_LIMIT_LINE_PREFIX=""
else
  RATE_LIMIT_LINE_PREFIX="# "
fi
export RATE_LIMIT_LINE_PREFIX

# ENABLE_API_LIMITING enables (uncomments) the rate limiting section of the config file.
if [[ "$(echo $ENABLE_API_LIMITING | tr '[:upper:]' '[:lower:]')" == "true" ]]; then
  API_LIMIT_LINE_PREFIX=""
else
  API_LIMIT_LINE_PREFIX="# "
fi
export API_LIMIT_LINE_PREFIX

# REAL_IP_ALLOWED_CIDR will default to our standard AWS VPC CIDR.
: "${REAL_IP_ALLOWED_CIDR:=0.0.0.0/0}"
export REAL_IP_ALLOWED_CIDR

# RATE_LIMIT_STATE_SIZE dictates how many IP state statuses are stored in memory (in MB). 1 = ~ 16,000 IPs.
: "${RATE_LIMIT_STATE_SIZE:=1}"
export RATE_LIMIT_STATE_SIZE

# RATE_LIMIT_REQUESTS dictates how many requests per second are allowed.
: "${RATE_LIMIT_REQUESTS:=256}"
export RATE_LIMIT_REQUESTS

# RATE_LIMIT_BURST_SIZE number of requests allowed to be sent to the burst queue.
if [[ -z "$RATE_LIMIT_BURST_SIZE" || "$RATE_LIMIT_BURST_SIZE" == "0" ]]; then
  RATE_LIMIT_BURST=""
else
  # RATE_LIMIT_BURST_NODELAY send requests from burst queue immediately with no delay.
  if [[ "$(echo $RATE_LIMIT_BURST_NODELAY | tr '[:upper:]' '[:lower:]')" == "false" ]]; then
    RATE_LIMIT_BURST=" burst=$RATE_LIMIT_BURST_SIZE"
  else
    RATE_LIMIT_BURST=" burst=$RATE_LIMIT_BURST_SIZE nodelay"
  fi
fi
export RATE_LIMIT_BURST

if [ -n "$DEBUG" ]; then
  echo -e "\nEnvironment variables:\n$(env)\n"
fi


#
# Configure SSL
#

if [ "$SELF_SIGNED" == "true" ]; then
  echo "Creating self signed certificate"
  /opt/scripts/self_signed_certificate.sh
else
  echo "Retrieving certificate from ACM"
  /opt/scripts/acm_certificate.sh
fi


#
# NGINX
#

# Replace variables $ENV{<environment varname>}
function ReplaceEnvironmentVariable() {
    grep -rl "\$ENV{\"$1\"}" $3|xargs -r \
        sed -i "s|\\\$ENV{\"$1\"}|$2|g"
}


# Restore "template" configuration for modification below
cp /default.conf /etc/nginx/conf.d/default.conf

# Replace all variables
for _curVar in `env | awk -F = '{print $1}'`;do
    # awk has split them by the equals sign
    # Pass the name and value to our function
    ReplaceEnvironmentVariable "${_curVar}" "${!_curVar}" /etc/nginx/conf.d/*
done

function certificate_expiration_check() {
  expires=$(openssl s_client -servername "$FQDN" -connect 127.0.0.1:443 2>/dev/null | openssl x509 -noout -dates | grep notAfter)
  expires_date=${expires:9}
  echo "Certificate expires on ${expires_date}"
}

sleep 4 && certificate_expiration_check &

# Run nginx
if [ "$DEBUG" == "true" ]; then
  echo 'Starting nginx-debug with extended logging'
  nginx-debug -g "daemon off;"
else
  echo 'Starting nginx'
  nginx -g "daemon off;"
fi
