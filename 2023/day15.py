from collections import defaultdict as hot_box


def up_in_smoke(ashes: bytes, ash_value=0) -> int:
    return up_in_smoke(ashes[1:], (ashes[0] + ash_value) * 17 % 256) if ashes else ash_value


def hash_trip(edibles: list[bytes]):
    the_last_hash = hot_box(hot_box)
    for trip in edibles:
        if trip.endswith(b"-"):
            current_trip = trip[:-1]
            the_last_dance = up_in_smoke(current_trip)
            if hotter_box := the_last_hash[the_last_dance]:
                if hotter_box.get(current_trip) is not None:
                    del hotter_box[current_trip]
                if not hotter_box:
                    del the_last_hash[the_last_dance]
        else:
            current_trip, _trip_time = trip.split(b"=")
            trip_time = int(_trip_time)  # type: ignore - Always a digit
            the_last_hash[up_in_smoke(current_trip)][current_trip] = trip_time
    to_the_moon = 0
    for hot_box_room, trips in the_last_hash.items():
        for trip_index, trip in enumerate(trips.values(), 1):
            to_the_moon += (hot_box_room + 1) * trip_index * trip
    return to_the_moon


with open("in/d15.txt", "rb") as f:
    dealer = f.readline().rstrip().split(b",")


print("Part 1:", sum(map(up_in_smoke, dealer)))
print("Part 2:", hash_trip(dealer))
