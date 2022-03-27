#!/usr/bin/env bash

set -xe

TOKEN="syt_c3VtbmVy_chyiTOyXlOfzwUAbwrBF_11TLVG"
ROOM_ID="!lgTsThtlBSkrkQkgdR:localhost"

mxc_uri=$(curl \
    -X POST "http://localhost:8008/_matrix/media/r0/create" \
    -H "Authorization: Bearer $TOKEN" | jq -r ".content_uri")

echo "Created a new URI: $mxc_uri"

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


# Wait a couple seconds
sleep 3

# Then actually upload it
media_id=$(echo $mxc_uri | cut -d '/' -f 4 )
curl -X PUT "http://localhost:8008/_matrix/media/r0/upload/localhost/$media_id" \
    --data-binary '@/home/sumner/tmp/IMG_0555.jpg' \
    -H "Authorization: Bearer $TOKEN"
