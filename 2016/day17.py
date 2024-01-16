from binascii import hexlify
from collections import deque
from hashlib import md5


def in_the_closet(part2: bool):
    m_step = "" if part2 else ("B" * 1000)
    q: deque[tuple[int, int, str]] = deque([(1, 1, d) for i, x in enumerate(C("")) if x in O and (d := DIR[i]) in "DR"])
    while q:
        row, col, steps = q.popleft()
        match steps[-1]:
            case "U":
                row -= 1
            case "D":
                row += 1
            case "L":
                col -= 1
            case "R":
                col += 1
        if GRID[row][col]:
            if (row, col) == END:
                if len(steps) > len(m_step) if part2 else (len(steps) < len(m_step)):
                    m_step = steps
                continue
            if not part2:
                if len(steps) >= len(m_step):
                    continue
            for i, b in enumerate(C(steps)):
                if b in O:
                    q.append((row, col, steps + DIR[i]))
    return m_step


with open("in/d17.txt") as f:
    closeted = f.read().rstrip()
GRID, O, DIR = tuple((0, *x, 0) for x in zip(*((0, *(1,) * 4, 0) for _ in range(4)))), set(b"bcdef"), "UDLR"
C, END = lambda x: hexlify(md5((closeted + x).encode()).digest())[:4], (4, 4)
print("Part 1:", in_the_closet(False))
print("Part 2:", len(in_the_closet(True)))
