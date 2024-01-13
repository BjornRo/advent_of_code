from collections import Counter


def roomizer(wroom, total=0, pid=-1):
    for r, _rid, chksm in wroom:
        r, rid = r.replace("-", ""), int(_rid)
        key = rid - 97
        if pid == -1 and "northpole" in "".join(chr((ord(c) + key) % 26 + 97) for c in r):
            pid = rid
        if "".join(cf[0] for cf in Counter(sorted(r)).most_common(5)) == chksm:
            total += rid
    return total, pid


with open("in/d4.txt") as f:
    print("Part 1: {}\nPart 2: {}".format(*roomizer(r.rstrip()[:-1].replace("[", "-").rsplit("-", 2) for r in f)))
