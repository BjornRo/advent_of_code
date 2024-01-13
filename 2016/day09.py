with open("in/d9.txt") as f:
    compressed = f.read().strip()

max_len = len(compressed)
total = i = 0
data, start_paren = "", False
while i < max_len:
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
total = i = 0
data, start_paren = "", False
while i < max_len:
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
