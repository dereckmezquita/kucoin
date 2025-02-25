#!/bin/bash

# DOCS: https://www.kucoin.com/docs/rest/account/deposit/get-deposit-history

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

# Calculate start time (3 years ago) in milliseconds
# Get current time in seconds and subtract 3 years (3 * 365 * 24 * 60 * 60 seconds)
START_TIME=$(($(date +%s) - 3*365*24*60*60))
# Convert to milliseconds
START_TIME_MS=$((START_TIME * 1000))

# End time is now (in milliseconds)
END_TIME_MS=$(($(date +%s) * 1000))

# Endpoint with query parameters
CURRENCY="BTC"
STATUS="SUCCESS"
CURRENT_PAGE="1"
PAGE_SIZE="50"

ENDPOINT="/api/v1/deposits?currency=${CURRENCY}&status=${STATUS}&startAt=${START_TIME_MS}&endAt=${END_TIME_MS}&currentPage=${CURRENT_PAGE}&pageSize=${PAGE_SIZE}"
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

# MacOS compatible date display
echo "Start time (3 years ago): $(date -r $START_TIME)"
echo "End time (now): $(date)"

# Make the request
curl "https://api.kucoin.com${ENDPOINT}" \
  -H "KC-API-KEY: ${API_KEY}" \
  -H "KC-API-SIGN: ${SIGNATURE}" \
  -H "KC-API-TIMESTAMP: ${TIMESTAMP}" \
  -H "KC-API-PASSPHRASE: ${ENCRYPTED_PASSPHRASE}" \
  -H "KC-API-KEY-VERSION: ${API_VERSION}" | python3 -m json.tool