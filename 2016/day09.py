def expand_data(comp_data: str, part2: bool, total=0, i=0, data=""):
    while i < len(comp_data):
        if comp_data[i] == "(":
            while comp_data[i] != ")":
                data += comp_data[i]
                i += 1
            (x, y), data = map(int, data[1:].split("x")), ""
            total += (expand_data(comp_data[i + 1 : i + x + 1], part2) if part2 else x) * y
            i += x + 1
            continue
        total += 1
        i += 1
    return total


with open("in/d9.txt") as f:
    compress = f.read().strip()
print("Part 1:", expand_data(compress, part2=False))
print("Part 2:", expand_data(compress, part2=True))
