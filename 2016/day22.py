from itertools import permutations

with open("in/d22.txt") as f:
    f.readline()
    f.readline()
    fs = [x.rstrip().rsplit("/", 1)[1].replace("node-x", "").replace("-y", " ").split() for x in f]

noodle = lambda row, col, size, use, avail, *_: (int(row), int(col), int(size[:-1]), int(use[:-1]), int(avail[:-1]))

# row_a, col_a, size_a, used_a, avail_a = noodle(*node_a)
# row_b, col_b, size_b, used_b, avail_b = noodle(*node_b)


viability = lambda node_a, node_b: (used := noodle(*node_a)[-2]) and (used <= noodle(*node_b)[-1])
print("Part 1:", sum(viability(a, b) for a, b in permutations(fs, 2)))
