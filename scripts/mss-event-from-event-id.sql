SELECT e.event_id, json::jsonb
FROM events e
JOIN event_json ej ON ej.event_id = e.event_id
WHERE e.room_id = '!wfXMNZgFQLJyDpctZg:beeper.com'
AND json::jsonb -> 'content' -> 'm.relates_to' ->> 'event_id' = '$o_90u8ovIoA1esrICAPoSjXEGUiTApVBWrTqscTUH_s'
