from hashlib import md5

with open("in/d4.txt") as f:
    string = f.read().strip()

found = False # just to stop printing part1.
for i in range(10_000_000):
    a, b, c = md5((string + str(i)).encode()).digest()[:3]
    if not found and not a and not b and 15 >= c:
        print("Part 1:", i)
        found = True
    if not a and not b and not c:
        print("Part 2:", i)
        break
