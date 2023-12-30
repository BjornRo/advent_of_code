with open("in/d17.txt") as f:
    containers = tuple(sorted(map(int, f.read().strip().split()), reverse=True))


def fill_it_up(containers: tuple[int, ...], capacity: int):
    if capacity == 150:
        return True
    if capacity >= 150 or not containers:
        return False

    total = 0
    for i in range(len(containers) - 1):
        total += fill_it_up(containers[i + 1 :], capacity + containers[i + 1])
    return total


def find_min(containers: tuple[int, ...], capacity: int, n_containers):
    if capacity == 150:
        return n_containers
    if capacity >= 150 or not containers:
        return float("inf")

    total = float("inf")
    for i in range(len(containers) - 1):
        total = min(find_min(containers[i + 1 :], capacity + containers[i + 1], n_containers + 1), total)
    return total


def min_ways_to_fill(containers: tuple[int, ...], capacity: int, n_containers: int, max_container: int | float):
    if capacity == 150 and n_containers == max_container:
        return True
    if capacity >= 150 or not containers or n_containers > max_container:
        return False

    total = 0
    for i in range(len(containers) - 1):
        total += min_ways_to_fill(containers[i + 1 :], capacity + containers[i + 1], n_containers + 1, max_container)
    return total


min_containers = float("inf")
for i in range(len(containers)):
    min_containers = min(find_min(containers[i:], containers[i], 1), min_containers)


total1 = total2 = 0
for i in range(len(containers)):
    total1 += fill_it_up(containers[i:], containers[i])
    total2 += min_ways_to_fill(containers[i:], containers[i], 1, min_containers)


print("Part 1:", total1)
print("Part 2:", total2)
