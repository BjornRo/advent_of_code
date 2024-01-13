from collections import Counter


def roomizer(wroom, total=0, pid=-1):
    for r, _rid, chksm in wroom:
        r, rid = r.replace("-", ""), int(_rid)
        if pid == -1 and "northpole" in "".join(chr((ord(c) + rid - 97) % 26 + 97) for c in r):
            pid = rid
        if "".join([*zip(*Counter(sorted(r)).most_common(5))][0]) == chksm:
            total += rid
    return total, pid


with open("in/d4.txt") as f:
    total, pid = roomizer(r.rstrip()[:-1].replace("[", "-").rsplit("-", 2) for r in f)
    print("Part 1:", total)
    print("Part 2:", pid)
