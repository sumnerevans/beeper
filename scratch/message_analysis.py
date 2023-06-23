#!/usr/bin/env python3

import sys
import json
from collections import defaultdict

with open(sys.argv[1], "r") as f:
    data = json.load(f)

counts = defaultdict(int)

for element in data:
    if element["fields"]["container"] != "hungryserv":
        continue
    
    counts[json.loads(element["line"])["message"]] += 1

for m, count in sorted(counts.items(), key=lambda x: x[1], reverse=True):
    print(f"{count:5} {m}")
