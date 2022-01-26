# https://matrix.beeper.com!/usr/bin/env python3

import json
import os
import sys
import time

import requests

OLD_DOMAINS = ("pulsar.im", "beeperhq.com", "nova.chat")


def make_url(part: str):
    base = os.environ.get("MATRIX_BASE_URL") or "https://matrix.beeper.com"
    return f"{base}/_matrix/client/r0{part}"


auth_token = sys.argv[1]

old_room_id, room_version = None, None
if len(sys.argv) > 2:
    old_room_id = sys.argv[2]
    if len(sys.argv) > 3:
        room_version = sys.argv[3]

old_room_id or input("Enter the room ID to upgrade: ")
room_version = room_version or input("Enter the new room version: ")

print(f"Ugrading {old_room_id} to v{room_version}")

print(f"Getting {old_room_id} state for migration")
state_events = requests.get(
    make_url(f"/rooms/{old_room_id}/state"),
    headers={"Authorization": f"Bearer {auth_token}"},
).json()

name = None
topic = None
members = []
initial_state_extra = []

old_power_level_content = None
power_level_content_override = None

for e in state_events:
    if e["type"] == "m.room.name":
        name = e["content"]["name"]
    elif e["type"] == "m.room.topic":
        topic = e["content"]["topic"]
    elif e["type"] == "m.room.member":
        if e["membershp"] != "join":
            # Only invite people who are currently in the room.
            continue

        username = e["state_key"]
        domain = username.split(":")[-1]
        if domain in OLD_DOMAINS:
            continue
        members.append(username)
    elif e["type"] == "m.room.power_levels":
        old_power_level_content = e["content"]
        power_level_content_override = e["content"]
        power_level_content_override["users"] = {
            user: power_level
            for user, power_level in power_level_content_override["users"].items()
            if user.split(":")[-1] not in OLD_DOMAINS
        }
    elif e["type"] in ("m.room.server_acl", "m.room.avatar"):
        initial_state_extra.append(
            {
                "type": e["type"],
                "state_key": e["state_key"],
                "content": e["content"],
            }
        )

assert name
assert old_power_level_content
assert power_level_content_override

last_message = requests.get(
    make_url(f"/rooms/{old_room_id}/messages"),
    params={"dir": "b", "limit": 1},
    headers={"Authorization": f"Bearer {auth_token}"},
).json()
old_room_last_event_id = last_message["chunk"][0]["event_id"]
print(f"Last message in {old_room_id}:", old_room_last_event_id)

create_room_request = {
    "visibility": "private",
    "name": name,
    "creation_content": {
        "predecessor": {
            "event_id": old_room_last_event_id,
            "room_id": old_room_id,
        },
        "room_version": room_version,
    },
    "power_level_content_override": power_level_content_override,
    "initial_state": [
        *initial_state_extra,
        # All Beeper rooms sholud be encrypted
        {
            "type": "m.room.encryption",
            "state_key": "",
            "content": {"algorithm": "m.megolm.v1.aes-sha2"},
        },
        # Always make history visibility shared
        {
            "type": "m.room.history_visibility",
            "state_key": "",
            "content": {"history_visibility": "shared"},
        },
        # Always make guest access forbidden
        {
            "type": "m.room.guest_access",
            "state_key": "",
            "content": {"guest_access": "forbidden"},
        },
        {
            "type": "m.room.join_rules",
            "state_key": "",
            "content": {
                "join_rule": "restricted",
                "allow": [
                    # The Beeper team space
                    {
                        "room_id": "!iXZMHoUhAYxTUqpVBB:beeper.com",
                        "type": "m.room_membership",
                    },
                    # Beeper team room
                    {
                        "room_id": "!StTxxbAqytkPgnaDUK:pulsar.im",
                        "type": "m.room_membership",
                    },
                ],
            },
        },
    ],
}
if topic:
    create_room_request["topic"] = topic

print("Create room request content:")
print(json.dumps(create_room_request, indent=2))

input("Press enter to continue")

print("Creating new room")
create_room_response = requests.post(
    make_url("/createRoom"),
    headers={"Authorization": f"Bearer {auth_token}"},
    json=create_room_request,
).json()

new_room_id = create_room_response["room_id"]

print(f"New room ID: {new_room_id}")
tombstone_content = {
    "body": f"This room has been upgraded to v{room_version}",
    "replacement_room": new_room_id,
}

# Tombstone the old room and make it so that you can't invite or send events to it
# anymore.
requests.put(
    make_url(f"/rooms/{old_room_id}/state/m.room.tombstone"),
    headers={"Authorization": f"Bearer {auth_token}"},
    json=tombstone_content,
)

old_power_level_content["events_default"] = 50
old_power_level_content["invite"] = 50
requests.put(
    make_url(f"/rooms/{old_room_id}/state/m.room.power_levels"),
    headers={"Authorization": f"Bearer {auth_token}"},
    json=old_power_level_content,
)

# Invite all old members to new room
for m in members:
    for i in range(3):  # 3 retries
        print(f"Invite {m}. Attempt {i}.")
        resp = requests.post(
            make_url(f"/rooms/{new_room_id}/invite"),
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"user_id": m},
        )
        if resp.status_code == 200:
            # Go to the next person
            break
        elif resp.status_code == 429:
            # Rate limited. Need to wait for cooldown.
            wait_ms = resp.json().get("retry_after_ms", 5000)
            print(f"Rate limiting kicked in. Waiting for {wait_ms+1000}ms")
            time.sleep(wait_ms + 1000)
