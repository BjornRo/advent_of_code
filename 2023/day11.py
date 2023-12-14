import time

start = time.time()
with open("d11.txt", "rt") as f:
    rows, cols = map(list,zip(*((i, j) for i, row in enumerate(f, 1) for j, col in enumerate(row.strip(), 1) if col == "#")))
    cols.sort()

def sum_list_distances(galaxy: list[int], multiplier: int) -> int:
    multiplier = multiplier - 1 or 1
    total = factor = curr_val = 0
    last_value = galaxy[0]
    for j in range(1, len(galaxy)):
        curr_val = galaxy[j]
        if (v := curr_val - last_value) > 1:
            factor += (v - 1) * multiplier
        galaxy[j] += factor
        last_value = curr_val
    galaxy.reverse()
    for i, g1 in enumerate(galaxy[:-1], 1):
        for g2 in galaxy[i:]:
            total += g1-g2
    return total

print("Part 1:", sum_list_distances(rows.copy(), 1) + sum_list_distances(cols.copy(), 1))
print("Part 2:", sum_list_distances(rows, 1000000) + sum_list_distances(cols, 1000000))
print(time.time() - start)
