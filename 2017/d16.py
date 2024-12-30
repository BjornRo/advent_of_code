from itertools import count
from string import ascii_lowercase

with open("in/d16.txt") as f:
    data = f.read().split(",")


def dancing(line: list[str]) -> list[str]:
    for i in data:
        if i[0] == "s":
            num = -int(i[1:])
            line = line[num:] + line[:num]
            continue
        x, y = map(int if i[0] == "x" else line.index, i[1:].split("/"))
        line[x], line[y] = line[y], line[x]
    return line


def part2() -> str:
    line = list(ascii)
    visited = {ascii: 0}
    values: list[str] = []
    for i in count(1):
        line = dancing(line)
        res = "".join(line)
        if res in visited:
            return values[1_000_000_000 % i - 1]
        visited[res] = i
        values.append(res)
    return ""


ascii = ascii_lowercase[:16]
print(f"Part 1: {"".join(dancing(list(ascii)))}")
print(f"Part 2: {part2()}")
