#!/usr/bin/env bash
set -xe

export TO=@help:localhost
export TO_DEVICE=YFLRNJCDVZ
export FROM_DEVICE=EGKNPDPUQT
export ROOM_ID="!izGhwmjhAbXsWdKWiC:localhost"
export SENDER_KEY="xrLxOfCwO62BnIaouKj/Q2j5TeI8Qeo+42MpF905owY"
export SESSION_ID="g/TLkkaydXJUlP6MGJRLdO+529uiLcuUcytkkINVpVE"

export NOW=$(date +%s)

jq -n '
{
  messages: {
    "\(env.TO)": {
      "\(env.TO_DEVICE)": {
        action: "request",
        body: {
          algorithm: "m.megolm.v1.aes-sha2",
          room_id: env.ROOM_ID,
          "sender_key": env.SENDER_KEY,
          "session_id": env.SESSION_ID
        },
        "request_id": "\(env.NOW)",
        "requesting_device_id": env.FROM_DEVICE
      }
    }
  }
}
' | curl -X PUT -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${AUTH_TOKEN}" \
        "http://localhost:8008/_matrix/client/r0/sendToDevice/m.room_key_request/$(date +%s)" \
        --data @-
