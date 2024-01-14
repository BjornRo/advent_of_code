from collections import defaultdict, deque


def botnet(string: str):
    sp_str = string.rstrip().split()
    if len(sp_str) == 6:
        _, value, _, _, _, bot_id = sp_str
        return int(value), int(bot_id)
    _bot, id1, _, _lowto, _, outbot1, id2, _, _highto, _, outbot2, id3 = sp_str  # len 12
    return int(id1), outbot1[0], int(id2), outbot2[0], int(id3)


with open("in/d10.txt") as f:
    queue = deque(sorted((botnet(s) for s in f), key=len))
chips, outputs, part1 = defaultdict(list[int]), defaultdict(list[int]), None
while queue:
    i = queue.popleft()
    match i:
        case value, bot_id:
            chips[bot_id].append(value)
        case bot_id, outbot1, outbot_id1, outbot2, outbot_id2 if len(vals := chips[bot_id]) == 2:
            low, high = sorted(vals)
            vals *= 0
            if low == 17 and high == 61:
                part1 = bot_id
            for ob, ob_id, val in (outbot1, outbot_id1, low), (outbot2, outbot_id2, high):
                target = chips if ob == "b" else outputs
                target[ob_id].append(val)
        case _:
            queue.append(i)


print("Part 1:", part1)
print("Part 2:", outputs[0][0] * outputs[1][0] * outputs[2][0])
