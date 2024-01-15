from binascii import hexlify
from collections import defaultdict
from hashlib import md5

with open("in/d14.txt") as f:
    salty = f.read().rstrip()
...


def triple(b: bytes) -> None | int:
    for i in range(len(b) - 2):
        if b[i] == b[i + 1] == b[i + 2]:
            return b[i]
    return None


def quin(b: bytes) -> None | int:
    for i in range(len(b) - 4):
        if b[i] == b[i + 1] == b[i + 2] == b[i + 3] == b[i + 4]:
            return b[i]
    return None


Index, Number = [int] * 2

valid = 0
triples: dict[Number, list[Index]] = defaultdict(list)
salty = "abc"
for i in range(1_000_000_000):
    hashish = hexlify(md5((salty + str(i)).encode()).digest())
    if (val := triple(hashish)) is not None:
        if (valq := quin(hashish)) is not None:
            for j in triples[valq][:]:
                if i <= j + 1000:
                    valid += 1
                if valid == 64:
                    print(i)
                triples[valq].remove(j)
        else:
            triples[val].append(i)
    if i > 40004:
        break
