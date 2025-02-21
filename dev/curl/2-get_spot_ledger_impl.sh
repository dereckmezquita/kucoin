#!/bin/bash

# Get server time
SERVER_TIME=$(curl -s 'https://api.kucoin.com/api/v1/timestamp' | grep -o '"data":[0-9]*' | cut -d':' -f2)

# Load API credentials from .env file
source .env
API_KEY="${KC_API_KEY}"
API_SECRET="${KC_API_SECRET}"
API_PASSPHRASE="${KC_API_PASSPHRASE}"
API_VERSION="2"

# Use server time
TIMESTAMP=$SERVER_TIME

# Set time range (30 days ago to 29 days ago - keeping within 24h window)
END_TIME=$((TIMESTAMP - (29 * 24 * 3600 * 1000)))  # 29 days ago
START_TIME=$((END_TIME - (24 * 3600 * 1000)))      # 30 days ago

# Print time range for debugging
echo "Time range:"
echo "Start time: $START_TIME ($(date -r $((START_TIME/1000)) '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'date conversion failed'))"
echo "End time: $END_TIME ($(date -r $((END_TIME/1000)) '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'date conversion failed'))"

# Endpoint with query parameters including time range
ENDPOINT="/api/v1/accounts/ledgers?startAt=${START_TIME}&endAt=${END_TIME}&pageSize=50&currentPage=1"
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
echo "Full endpoint: ${ENDPOINT}"
echo "Signature: ${SIGNATURE}"
echo "Encrypted passphrase: ${ENCRYPTED_PASSPHRASE}"

# Make the request with uppercase headers and format JSON output
curl -v "https://api.kucoin.com${ENDPOINT}" \
  -H "KC-API-KEY: ${API_KEY}" \
  -H "KC-API-SIGN: ${SIGNATURE}" \
  -H "KC-API-TIMESTAMP: ${TIMESTAMP}" \
  -H "KC-API-PASSPHRASE: ${ENCRYPTED_PASSPHRASE}" \
  -H "KC-API-KEY-VERSION: ${API_VERSION}" | jq '.'
