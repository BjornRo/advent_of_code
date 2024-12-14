from re import findall

with open("in/d14.txt") as f:
    data = f.read().strip()
W, H = 101, 103

robots = [[int(n) for n in findall(r"(-?\d+)", item)] for item in data.split("\n")]


def simulate(t):
    return [((sx + t * vx) % W, (sy + t * vy) % H) for (sx, sy, vx, vy) in robots]


from statistics import variance

bx, bxvar, by, byvar = 0, 10 * 100, 0, 10 * 1000
for t in range(103):
    xs, ys = zip(*simulate(t))
    if (xvar := variance(xs)) < bxvar:
        bx, bxvar = t, xvar
    if (yvar := variance(ys)) < byvar:
        by, byvar = t, yvar
        
print(bx, by)
print("Part 2:", bx + ((pow(W, -1, H) * (by - bx)) % H) * W)
