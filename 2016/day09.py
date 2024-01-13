with open("in/d9.txt") as f:
    compressed = f.read().strip()
MAX_LEN = len(compressed)

data, start_paren, total, i = "", False, 0, 0
while i < MAX_LEN:
    if compressed[i] == ")":
        (x, y), data, start_paren = map(int, data.split("x")), "", False
        total += x * y
        i += x
    elif compressed[i] == "(":
        start_paren = True
    elif start_paren:
        data += compressed[i]
    else:
        total += 1
    i += 1
print("Part 1", total)

# Part 2
"""
(27x12)(20x12)(13x14)(7x10)(1x12)A
12*12*14*10*12 * (A) = 241920
Parse len of 27(first), then "collapse"
"""
data, start_paren, total, i = "", False, 0, 0
while i < MAX_LEN:
    if compressed[i] == ")":
        (x, y), data, start_paren = map(int, data.split("x")), "", False
        total += x * y
        i += x  # TODO do not move the cursor, but check recursively(?) if more parts exists.
    elif compressed[i] == "(":
        start_paren = True
    elif start_paren:
        data += compressed[i]
    else:
        total += 1
    i += 1
print(total)
