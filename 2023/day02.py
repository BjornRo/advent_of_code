from time import perf_counter as time_it

start_it = time_it()

# Part 1
with open("in/d2.txt", "rt") as f:
    print("Part 1:", sum(id for id, game in enumerate(f.read().strip().split("\n"), 1) if all(c == "r" and n <= 0 or c == "g" and n <= 1 or c == "b" and n <= 2 for c, n in ((color[0], int(num) - 12) for num, color in ( i.strip().split(" ") for g in (draw.split(",") for draw in game.split(":").pop().split(";")) for i in g)))))

# # Part 2
# with open("in/d2.txt", "rt") as f:
#     _sum = 0
#     for id, game in enumerate(f.read().strip().split("\n"), 1):
#         r = []
#         g = []
#         b = []
#         for c,n in ((color[0], int(num)) for num, color in (i.strip().split(" ") for g in (draw.split(",") for draw in game.split(":").pop().split(";")) for i in g)):
#             match c:
#                 case "r":
#                     r.append(n)
#                 case "b":
#                     b.append(n)
#                 case "g":
#                     g.append(n)
#         _sum += max(r) * max(g) * max(b)
#     print(_sum)

# Nicer solution to part 2
with open("in/d2.txt", "rt") as f:
    print("Part 2:", sum(max(v[:c.index("g")]) * max(v[c.index("g"):c.index("r")]) * max(v[c.index("r"):]) for x in f.read().strip().split("\n") for c,v in [list(zip(*sorted((j[0], int(k)) for k, j in (i.strip().split(" ") for g in (d.split(",") for d in x.split(":").pop().split(";")) for i in g))))]))

print("Finished in:", round(time_it() - start_it, 4), "secs")
