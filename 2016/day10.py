from collections import defaultdict, deque


def botnet(string: str):
    sp_str = string.rstrip().split()
    if len(sp_str) == 6:
        _, value, _, _, _, bot_id = sp_str
        return int(value), int(bot_id)
    _bot, id1, _, _lowto, _, outbot1, id2, _, _highto, _, outbot2, id3 = sp_str  # len 12
    return int(id1), outbot1[0] == "b", int(id2), outbot2[0] == "b", int(id3)


with open("in/d10.txt") as f:
    queue, chip, out, p1 = deque(sorted((botnet(s) for s in f), key=len)), defaultdict(list), defaultdict(list), -1
while queue:
    match queue.popleft():
        case value, bot_id:
            chip[bot_id].append(value)
        case bot_id, outbot1, outbot_id1, outbot2, outbot_id2 if len(vals := chip[bot_id]) == 2:
            low, high = sorted(vals)
            vals *= 0
            if low == 17 and high == 61:
                p1 = bot_id
            for is_bot, ob_id, val in (outbot1, outbot_id1, low), (outbot2, outbot_id2, high):
                (chip if is_bot else out)[ob_id].append(val)
        case i:
            queue.append(i)

print("Part 1:", p1)
print("Part 2:", out[0][0] * out[1][0] * out[2][0])
