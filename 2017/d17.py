from collections import deque

with open("in/d17.txt") as f:
    data = int(f.read().rstrip())


def solver(end: int):
    queue = deque([0])
    for i in range(1, end + 1):
        queue.rotate(-data)
        queue.append(i)
    return queue


q = solver(50_000_000)  # Bruteforce
print(f"Part 1: {solver(2017)[0]}")
print(f"Part 2: {q[q.index(0) + 1]}")
