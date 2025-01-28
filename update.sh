#!/usr/bin/env bash

set -ex

CURRENT_NUMBER=$(grep -Po '<!-- value -->[0-9]+' index.html | grep -Po '[0-9]*')
echo "Current number is $CURRENT_NUMBER"

TIMESTAMP_YESTERDAY=$(date -d "24 hours ago" +"%Y-%m-%dT%H:%M:%S%z")

UPTIME=$(curl https://updown.io/api/checks/4yqp/metrics\?from\=2025-01-27T01:04:44+0100\&api-key\=ro-gvHnFHvKHQJNhzskr4qc | jq ".uptime" | grep -Po '^[0-9]+')
NEW_NUMBER=0
if test "$UPTIME" -ge 98; then
    NEW_NUMBER=$((CURRENT_NUMBER + 1))
else
    NOW=$(date -d "24 hours ago" +"%s")
    sed -i 's/<!-- lastdown: [0-9]* -->/<!-- lastdown: '$NOW' -->/' index.html
fi

sed -i "s/<!-- value -->[0-9]*/<!-- value -->$NEW_NUMBER/" index.html
echo "New number is $NEW_NUMBER"
