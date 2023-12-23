for cz, bh, b in reversed(settled_stack):
    print(cz, bh)
    for e in b:
        print(e)
print()
for b in cum_height:
    print(b)


brick_supports_next: dict[int, list[int]] = {}
ci = 0
for ci, (cz1, b_height1, b1) in enumerate(settled_stack):
    brick_supports_next[ci] = []
    cz1 += b_height1
    # Find next overlapping pieces to current pieces
    for ci2, (cz2, b_height2, b2) in enumerate(settled_stack[ci + 1 :], ci + 1):
        if cz1 == cz2:
            if overlaps_xy(b1, b2):
                brick_supports_next[ci].append(ci2)
        elif cz1 < cz2:
            break

brick_supports_previous: defaultdict[int, list[int]] = defaultdict(list)
for idx, s in brick_supports_next.items():
    for i in s:
        brick_supports_previous[i].append(idx)
brick_next = brick_supports_next
brick_prev = dict(brick_supports_previous)


# @cache
def benga(idx: int, removed: int):
    if idx == len(settled_stack):
        return removed
    result = 0
    n_bricks_next = len(brick_next[idx])
    print(n_bricks_next)
    print(brick_prev)
    print(brick_next)
    breakpoint()
    for next_idx in brick_next[idx]:
        pass


# print(benga(0, 0))


def overlaps_xy(b1: list[list[int]], b2: list[list[int]]) -> bool:
    for i in range(MAX_GRID):
        for j in range(MAX_GRID):
            if b1[i][j] and b2[i][j]:
                return True
    return False
