#!/usr/bin/env bash
set -xe

jq -n '{"purge": true}' | curl -X DELETE -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${AUTH_TOKEN}" \
        "http://localhost:8008/_synapse/admin/v1/rooms/$1" \
        --data @-
