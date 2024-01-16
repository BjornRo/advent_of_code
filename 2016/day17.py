from binascii import hexlify
from collections import deque
from hashlib import md5


def in_the_closet(part2: bool):
    m_step = "" if part2 else ("B" * 1000)
    q: deque[tuple[int, int, str]] = deque([(1, 1, l) for l, x in zip(L, C("")) if x in E and l in "DR"])
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
        if H[row][col]:
            if (row, col) == P:
                if len(steps) > len(m_step) if part2 else (len(steps) < len(m_step)):
                    m_step = steps
                continue
            if not part2:
                if len(steps) >= len(m_step):
                    continue
            for l, s in zip(L, C(steps)):
                if s in E:
                    q.append((row, col, steps + l))
    return m_step


with open("in/d17.txt") as f:
    C, loseted = lambda x: hexlify(md5((loseted + x).encode()).digest())[:4], f.read().rstrip()
H, E, L, P = tuple((0, *x, 0) for x in zip(*((0, *(1,) * 4, 0) for _ in range(4)))), set(b"bcdef"), "UDLR", (4, 4)
print("Part 1:", in_the_closet(False))
print("Part 2:", len(in_the_closet(True)))
