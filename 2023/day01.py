from time import perf_counter as time_it

start_it = time_it()

with open("in/d1.txt", "rt") as f:
    infile = f.read().strip().split("\n")

def part1(x: str):
    start = end = ""
    for i in x:
        if i.isdigit():
            if not start:
                start = end = i
            else:
                end = i
    return int(start + end)

def part2(x: str, rev=False) -> str:
    x = x[::-1] if rev else x
    for i, c in enumerate(x):
        for j, s in enumerate(("one","two","three","four","five","six","seven","eight","nine"), 1):
            s_prim = s[::-1] if rev else s
            if s_prim in x[:i]:
                return str(j)
        if c.isdigit():
            return c
    return ""

print("Part 1:", sum(map(part1, infile)))
print("Part 2:", sum(map(lambda x: int(part2(x) + part2(x, True)), infile)))
print("Finished in:", round(time_it() - start_it, 4), "secs")
