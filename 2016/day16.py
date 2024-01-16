def curvature(disk_size: int, data: list[bool]):
    while len(data) < disk_size:
        data = data + [False] + [not x for x in data[::-1]]
    data = data[:disk_size]
    while len(data) % 2 == 0:
        data = [a == b for a, b in zip(data[::2], data[1::2])]
    return "".join(map(str, map(int, data)))


with open("in/d16.txt") as f:
    binner = list(map(bool, map(int, f.read().rstrip())))

print("Part 1:", curvature(272, binner))
print("Part 2:", curvature(35651584, binner))
