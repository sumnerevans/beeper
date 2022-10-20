#! /usr/bin/env python3

import json
import sys
from pathlib import Path
from urllib.parse import parse_qs, urlparse

import requests


def parse_event_since(since: str) -> int:
    for part in since.split("_"):
        if part[0] == "e":
            return int(part[1:])
    return 0


user, cluster, token, *room_ids = sys.argv[1:]

with open(Path("/home/sumner/tmp/allsyncs")) as f:
    since_params_raw = [parse_qs(urlparse(url).query).get("since") for url in f]

since_params = [s[0] for s in since_params_raw if s]
since_params.reverse()

for since1, since2 in zip(since_params, since_params[1:]):
    print(since1, "->", since2)
    if parse_event_since(since1) == parse_event_since(since2):
        continue

    req = requests.get(
        f"https://{user}.users.{cluster}.bridges.beeper.com/hungryserv/_matrix/client/r0/sync?filter=0&since={since1}&until={since2}&timeout=0",
        headers={"Authorization": f"Bearer {token}"},
    )

    resp = req.json()

    print(json.dumps(req.json(), indent=2))
    input()
