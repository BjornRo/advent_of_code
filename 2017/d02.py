with open("in/d02.txt") as f:
    data = [sorted(map(int, x.split())) for x in f]

print(f"Part 1: {sum([max(x) - min(x) for x in data])}")
print(
    f"Part 2: {sum([d[j] // d[i] for d in data for i in range(len(d)) for j in range(i + 1, len(d)) if d[j] // d[i] == d[j] / d[i]])}"
)
