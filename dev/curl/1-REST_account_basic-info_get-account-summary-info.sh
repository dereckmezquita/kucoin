#!/bin/bash

# DOCS: https://www.kucoin.com/docs/rest/account/basic-info/get-account-summary-info

# First get the server time and extract just the timestamp number
SERVER_TIME=$(curl -s 'https://api.kucoin.com/api/v1/timestamp' | grep -o '"data":[0-9]*' | cut -d':' -f2)

# Your API credentials
source .env
API_KEY="${KC_API_KEY}"
API_SECRET="${KC_API_SECRET}"
API_PASSPHRASE="${KC_API_PASSPHRASE}"
API_VERSION="2"

# Use server time
TIMESTAMP=$SERVER_TIME

# Endpoint
ENDPOINT="/api/v2/user-info"
METHOD="GET"

# Create string to sign
STRING_TO_SIGN="${TIMESTAMP}${METHOD}${ENDPOINT}"

# Generate signature
SIGNATURE=$(echo -n "${STRING_TO_SIGN}" | openssl dgst -sha256 -hmac "${API_SECRET}" -binary | base64)

# Generate encrypted passphrase
ENCRYPTED_PASSPHRASE=$(echo -n "${API_PASSPHRASE}" | openssl dgst -sha256 -hmac "${API_SECRET}" -binary | base64)

# Debug output
echo "Timestamp: ${TIMESTAMP}"
echo "String to sign: ${STRING_TO_SIGN}"
echo "Signature: ${SIGNATURE}"
echo "Encrypted passphrase: ${ENCRYPTED_PASSPHRASE}"

# Make the request
curl -v "https://api.kucoin.com${ENDPOINT}" \
  -H "KC-API-KEY: ${API_KEY}" \
  -H "KC-API-SIGN: ${SIGNATURE}" \
  -H "KC-API-TIMESTAMP: ${TIMESTAMP}" \
  -H "KC-API-PASSPHRASE: ${ENCRYPTED_PASSPHRASE}" \
  -H "KC-API-KEY-VERSION: ${API_VERSION}"
