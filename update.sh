#!/usr/bin/env bash

set -ex

CURRENT_NUMBER=$(grep -Po '<!-- value -->[0-9]+' index.html | grep -Po '[0-9]*')
echo "Current number is $CURRENT_NUMBER"

TIMESTAMP_YESTERDAY=$(date -d "24 hours ago" +"%Y-%m-%dT%H:%M:%S%z")

IS_DOWN=0

# Fetch uptime without exposing the API key in xtrace output
set +x
UPTIME=$(curl "https://updown.io/api/checks/4yqp/metrics?from=2025-01-27T01:04:44+0100&api-key=${UPDOWN_API_KEY}" 2>/dev/null | jq -r '.uptime // empty' | grep -Po '^[0-9]+' || true)
set -x
if [ -z "$UPTIME" ]; then
    echo "Failed to fetch or parse uptime from updown.io"
    IS_DOWN=1
elif test "$UPTIME" -lt 98; then
    echo "updown.io uptime is ${UPTIME}% (below 98% threshold)"
    IS_DOWN=1
fi

# Check if skyfeed.lol resolves to an IP address
if ! host skyfeed.lol > /dev/null 2>&1; then
    echo "DNS resolution for skyfeed.lol failed"
    IS_DOWN=1
fi

# Check if skyfeed.lol is reachable via ping
if ! ping -c 1 -W 5 skyfeed.lol > /dev/null 2>&1; then
    echo "Ping to skyfeed.lol failed"
    IS_DOWN=1
fi

NEW_NUMBER=0
if test "$IS_DOWN" -eq 0; then
    NEW_NUMBER=$((CURRENT_NUMBER + 1))
else
    NOW=$(date -d "24 hours ago" +"%s")
    sed -i 's/<!-- lastdown: [0-9]* -->/<!-- lastdown: '$NOW' -->/' index.html
fi

sed -i "s/<!-- value -->[0-9]*/<!-- value -->$NEW_NUMBER/" index.html
echo "New number is $NEW_NUMBER"
