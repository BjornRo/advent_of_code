def fill_it_up(buckets: tuple[int, ...], capacity: int) -> int:
    if capacity == 150:
        return True
    if capacity >= 150 or not buckets:
        return False
    total = 0
    for i in range(len(buckets) - 1):
        total += fill_it_up(buckets[i + 1 :], capacity + buckets[i + 1])
    return total


def find_min(buckets: tuple[int, ...], capacity: int, n_buckets: int) -> int | float:
    if capacity == 150:
        return n_buckets
    if capacity >= 150 or not buckets:
        return float("inf")
    total = float("inf")
    for i in range(len(buckets) - 1):
        total = min(find_min(buckets[i + 1 :], capacity + buckets[i + 1], n_buckets + 1), total)
    return total


def min_ways_to_fill(buckets: tuple[int, ...], capacity: int, n_buckets: int, max_buckets: int | float) -> int | float:
    if capacity == 150 and n_buckets == max_buckets:
        return True
    if capacity >= 150 or not buckets or n_buckets > max_buckets:
        return False
    total = 0
    for i in range(len(buckets) - 1):
        total += min_ways_to_fill(buckets[i + 1 :], capacity + buckets[i + 1], n_buckets + 1, max_buckets)
    return total


with open("in/d17.txt") as f:
    buckets = tuple(sorted(map(int, f.read().strip().split()), reverse=True))


min_containers = float("inf")
for i in range(len(buckets)):
    min_containers = min(find_min(buckets[i:], buckets[i], 1), min_containers)
    if isinstance(min_containers, int):
        break
assert isinstance(min_containers, int)

total1 = total2 = 0
for i in range(len(buckets)):
    total1 += fill_it_up(buckets[i:], buckets[i])
    total2 += min_ways_to_fill(buckets[i:], buckets[i], 1, min_containers)


print("Part 1:", total1)
print("Part 2:", total2)
