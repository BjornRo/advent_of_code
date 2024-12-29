from itertools import batched

with open("in/d10.txt") as f:
    raw_data = f.read().rstrip()


def part1(inputs: list[int]) -> int:
    circ_list = list(range(256))
    skip_size = 0
    curr_position = 0
    for i in inputs:
        for j in range(i // 2):
            k = (curr_position + j) % len(circ_list)
            l = (curr_position + i - j - 1) % len(circ_list)
            circ_list[k], circ_list[l] = circ_list[l], circ_list[k]
        curr_position = (curr_position + i + skip_size) % len(circ_list)
        skip_size += 1
    return circ_list[0] * circ_list[1]


def part2(inputs: list[int]):
    circ_list = list(range(256))
    skip_size = 0
    curr_position = 0
    for _ in range(64):
        for i in inputs:
            for j in range(i // 2):
                k = (curr_position + j) % len(circ_list)
                l = (curr_position + i - j - 1) % len(circ_list)
                circ_list[k], circ_list[l] = circ_list[l], circ_list[k]
            curr_position = (curr_position + i + skip_size) % len(circ_list)
            skip_size += 1
    dense_hash = []
    for i in batched(circ_list, 16):
        dhash = 0
        for j in i:
            dhash ^= j
        dense_hash.append(hex(dhash)[2:])
    return "".join(dense_hash)


print(f"Part 1: {part1(list(map(int, raw_data.split(","))))}")
print(f"Part 2: {part2(list(bytearray(list(raw_data.encode()) + [17,31,73,47,23])))}")
