#!/usr/bin/env bash

for i in {1..405}; do
    data='{"checkpoints": [{"event_type":"m.room.message","event_id": "$test'
    data="$data$i\",\"room_id\":\"!test:foo\",\"step\":\"BRIDGE\",\"status\":\"SUCCESS\", \"reported_by\":\"BRIDGE\"}]}"

    curl http://localhost:8585/v1/send_message_checkpoints/sumner/slack \
        -X POST \
        --data "$data"
done
