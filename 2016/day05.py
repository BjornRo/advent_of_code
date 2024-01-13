from hashlib import md5

with open("in/d5.txt") as f:
    puzzle = f.read().rstrip()

pw, pw2 = [], [""] * 8
for i in range(1_000_000_000):
    a, b, c, d = md5((puzzle + str(i)).encode()).digest()[:4]
    if not a and not b and 15 >= c:
        if len(pw) != 8:
            pw.append(hex(c)[2])
        if c <= 7 and not pw2[c]:
            pw2[c] = hex(d)[2]
        if len(pw) == 8 and all(pw2):
            break

print("Part 1:", "".join(pw))
print("Part 2:", "".join(pw2))
