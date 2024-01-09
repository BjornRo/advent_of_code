from time import perf_counter as time_it

start_it = time_it()

def solver(content: list[tuple[list[int], int]], joker: bool) -> int:
    buckets = tuple([] for _ in range(7))
    for pair in content:
        if joker:
            hand = tuple(x for x in pair[0] if x != 11)
            jokers = 5 - len(hand)
        else:
            hand, jokers = pair[0], 0

        hand_set = set(hand)
        match len(hand_set):
            case 0 | 1:
                bucket_num = 6
            case 2 | 3 as l:
                bucket_num = 3 if l == 3 else 5
                for i in hand_set:
                    if hand.count(i) + jokers > 5 - l:
                        break
                else:
                    bucket_num -= 1
            case l:
                bucket_num = 5 - l
        buckets[bucket_num].append(pair)
    out_value, index = 0, 0
    for b in (p for p in buckets if p):
        for _, value in sorted((([1 if joker and k == 11 else k for k in h], v) for h, v in b)):
            index += 1
            out_value += value * index
    return out_value


m = {"T": 10, "J": 11, "Q": 12, "K": 13, "A": 14}
i = [([m[c] if c in m else int(c) for c in i], int(j)) for i, j in (x.split(" ") for x in open("in/d7.txt"))]
print("Part 1:", solver(i, False))
print("Part 2:", solver(i, True))
print("Finished in:", round(time_it() - start_it, 4), "secs")
