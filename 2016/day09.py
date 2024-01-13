def expand_data(comp_data: str, part2: bool, total=0, i=0, start_paren=False):
    comp_len, data = len(comp_data), []
    while i < comp_len:
        if comp_data[i] == ")":
            x, y = map(int, "".join(data).split("x"))
            total += y * (expand_data(comp_data[i + 1 : i + x + 1], part2) if part2 else x)
            i += x
            data *= 0
            start_paren = False
        elif comp_data[i] == "(":
            start_paren = True
        elif start_paren:
            data.append(comp_data[i])
        else:
            total += 1
        i += 1
    return total


with open("in/d9.txt") as f:
    compress = f.read().strip()
print("Part 1:", expand_data(compress, False))
print("Part 2:", expand_data(compress, True))
