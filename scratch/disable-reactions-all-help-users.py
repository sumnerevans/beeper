#!/usr/bin/env python3

import json
import sys

import asyncio
import aiohttp

ACCESS_TOKEN = sys.argv[1]
headers = {"Authorization": "Bearer " + ACCESS_TOKEN}


async def disallow_reactions(session: aiohttp.ClientSession, room_id: str) -> None:
    print(f"  {room_id}: ensuring it's a support chat")
    if (
        await session.get(
            f"https://matrix.beeper.com/_matrix/client/v3/rooms/{room_id}/state/com.beeper.support_chat",
            headers=headers,
        )
    ).status != 200:
        print(f"  {room_id}: skipping because it's not a support chat")
        return

    print(f"  {room_id}: getting power levels")
    power_levels_content = await (
        await session.get(
            f"https://matrix.beeper.com/_matrix/client/v3/rooms/{room_id}/state/m.room.power_levels",
            headers=headers,
        )
    ).json()

    if power_levels_content["events"].get("m.reaction", 0) == 50:
        print(f"  {room_id}: already has the correct power level for reactions")
        return

    print(f"  {room_id}: setting power levels")
    power_levels_content["events"]["m.reaction"] = 50

    resp = await session.put(
        f"https://matrix.beeper.com/_matrix/client/v3/rooms/{room_id}/state/m.room.power_levels",
        headers=headers,
        json=power_levels_content,
    )

    if resp.status == 200:
        print(f"  {room_id}: SUCCESS")
    else:
        print(f"  {room_id}: FAILED")
        raise Exception(str(await resp.read()))


async def main() -> None:
    async with aiohttp.ClientSession() as session:
        async with session.get(
            "https://matrix.beeper.com/_matrix/client/v3/joined_rooms", headers=headers
        ) as resp:
            assert resp.status == 200
            joined_rooms = (await resp.json())["joined_rooms"]

        print(f"There are {len(joined_rooms)} rooms")
        input("press enter to continue")

        # iterate through chunks of 20 rooms at a time
        for i in range(0, len(joined_rooms), 20):
            print()
            print()
            print(f"Processing rooms {i}-{i+9} (/{len(joined_rooms)})")
            tasks = [
                disallow_reactions(session, room_id)
                for room_id in joined_rooms[i : i + 20]
            ]
            await asyncio.gather(*tasks)


loop = asyncio.get_event_loop()
loop.run_until_complete(main())
