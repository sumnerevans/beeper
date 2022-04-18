#!/usr/bin/env bash

set -xe

TOKEN="syt_c3VtbmVy_chyiTOyXlOfzwUAbwrBF_11TLVG"
ROOM_ID="!lgTsThtlBSkrkQkgdR:localhost"

mxc_uri=$(curl -X POST "http://localhost:8008/_matrix/media/v3/upload" \
    --data-binary '@/home/sumner/tmp/IMG_0555.jpg' \
    -H "Authorization: Bearer $TOKEN" | jq -r ".content_uri")

# Send a message referencing that URI
jq -n --arg URI $mxc_uri '
{
    body: "test.jpg",
    msgtype: "m.image",
    url: $URI,
    info: {
        size: 1808770,
        mimetype: "image/jpg",
        w: 4032,
        h: 2268,
        "xyz.amorgan.blurhash": "LCEDe?IVjDWB03%N%Mae_4adIpoe",
    }
}
' | curl -X PUT "http://localhost:8008/_matrix/client/r0/rooms/$ROOM_ID/send/m.room.message/m.`date +%s`?access_token=$TOKEN" --data @-
