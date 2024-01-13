def expand_data(comp_data: str, part2: bool, total=0, i=0, start_paren=False, data=""):
    while i < len(comp_data):
        if comp_data[i] == ")":
            x, y = map(int, data.split("x"))
            total += (expand_data(comp_data[i + 1 : i + x + 1], part2) if part2 else x) * y
            i += x
            start_paren, data = False, ""
        elif comp_data[i] == "(":
            start_paren = True
        elif start_paren:
            data += comp_data[i]  # only a few chars, list-building less efficent.
        else:
            total += 1
        i += 1
    return total


with open("in/d9.txt") as f:
    compress = f.read().strip()
print("Part 1:", expand_data(compress, part2=False))
print("Part 2:", expand_data(compress, part2=True))
