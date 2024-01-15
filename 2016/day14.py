from binascii import hexlify
from collections import defaultdict
from hashlib import md5


def hashinator(part2: bool, valid=0):
    triples: dict[int, list[tuple[int, int]]] = defaultdict(list)
    for i in range(1_000_000):
        hashish = hexlify(md5((SALTY + str(i)).encode()).digest())
        if part2:
            for _ in range(2016):
                hashish = hexlify(md5(hashish).digest())
        if (val := n_tester(hashish, 3)) != -1:
            triples[val].append((i, i + 1000))
        if (val := n_tester(hashish, 5)) != -1:
            for s, e in list(triples[val]):
                if i <= e:
                    if s < i:
                        valid += 1
                        if valid == 64:
                            return s
                else:
                    triples[val].remove((s, e))


def n_tester(b: bytes, length: int) -> int:
    for i in range(len(b) - length + 1):
        for j in range(1, length):
            if b[i] != b[i + j]:
                break
        else:
            return b[i]
    return -1


with open("in/d14.txt") as f:
    SALTY = f.read().rstrip()
print("Part 1:", hashinator(part2=False))
print("Part 2:", hashinator(part2=True))
