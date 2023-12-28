from hashlib import md5

input = "bgvyzdsv"
found = False
for i in range(10_000_000):
    a, b, c = md5((input + str(i)).encode()).digest()[:3]
    if not a and not b and not c:
        print("Part 2:", i)
        break
    if not found and not a and not b and 15 >= c:
        print("Part 1:", i)
        found = True
