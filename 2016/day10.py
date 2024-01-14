def botnet(string: str):
    sp_str = string.rstrip().split()
    if len(sp_str) == 6:
        _, value, _, _, _, bot_id = sp_str
        return int(value), int(bot_id)
    # len 12
    _bot, id1, _, _lowto, _, outbot1, id2, _, _highto, _, outbot2, id3 = sp_str
    return int(id1), outbot1[0], int(id2), outbot2[0], int(id3)


with open("in/d10.txt") as f:
    instructions = tuple(botnet(s) for s in f)

