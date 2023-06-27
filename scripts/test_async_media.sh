#!/usr/bin/env bash

set -xe

TOKEN="syt_c3VtbmVy_XEUthdZXpLDATyBRnpYh_22LNVr"
ROOM_ID="!BYjOHJlBisqaRJHQAc:localhost"

# for i in {1..3}; do
#     curl \
#         -X POST "http://localhost:8008/_matrix/media/v3/create" \
#         -H "Authorization: Bearer $TOKEN"
# done

# exit 1

mxc_uri=$(curl \
    -X POST "http://localhost:8008/_matrix/media/v3/create" \
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
sleep 10

# Then actually upload it
media_id=$(echo $mxc_uri | cut -d '/' -f 4 )
curl -X PUT "http://localhost:8008/_matrix/media/v3/upload/localhost/$media_id" \
    --data-binary '@/home/sumner/tmp/IMG_0555.jpg' \
    -H "Authorization: Bearer $TOKEN" &

curl -X PUT "http://localhost:8008/_matrix/media/v3/upload/localhost/$media_id" \
    --data-binary '@/home/sumner/tmp/IMG_0555.jpg' \
    -H "Authorization: Bearer $TOKEN"
