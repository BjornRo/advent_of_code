with open("in/d9.txt") as f:
    compress = f.read().strip()
MAX_LEN = len(compress)

data, start_paren, total, i = "", False, 0, 0
while i < MAX_LEN:
    if compress[i] == ")":
        (x, y), data, start_paren = map(int, data.split("x")), "", False
        total += x * y
        i += x
    elif compress[i] == "(":
        start_paren = True
    elif start_paren:
        data += compress[i]
    else:
        total += 1
    i += 1
print("Part 1", total)


# Part 2
def expand_data(comp_data: str):
    comp_len = len(comp_data)
    data, start_paren, total, i = "", False, 0, 0
    while i < comp_len:
        if comp_data[i] == ")":
            (x, y), data, start_paren = map(int, data.split("x")), "", False
            total += expand_data(comp_data[i + 1 : i + x + 1]) * y
            i += x
        elif comp_data[i] == "(":
            start_paren = True
        elif start_paren:
            data += comp_data[i]
        else:
            total += 1
        i += 1
    return total


print(expand_data(compress))
