#! /usr/bin/env bash

set -xe

room_id=${1:-}
if [[ $room_id == "" ]]; then
    echo "Enter the room ID to upgrade"
    read room_id
fi

echo "Upgrading $room_id"

curl -H "Authorization: Bearer ${AUTH_TOKEN}" \
    "https://matrix.beeper.com/_matrix/client/r0/rooms/$room_id/state/m.room.create"
