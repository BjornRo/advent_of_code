from collections import deque

with open("in/d17.txt") as f:
    data = int(f.read().rstrip())


def part1():
    queue = deque([0])
    for i in range(1, 2017 + 1):
        queue.rotate(-data)
        queue.append(i)
    return queue.popleft()


def part2():
    pos_zero = 0
    pos_zero_plus = 0
    for i in range(1, 50_000_000 + 1):
        new_pos = (pos_zero + data) % i
        if new_pos == 0:
            pos_zero_plus = i
        pos_zero = new_pos + 1
    return pos_zero_plus


print(f"Part 1: {part1()}")
print(f"Part 2: {part2()}")
