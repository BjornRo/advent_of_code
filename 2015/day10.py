def look_and_say(string: str) -> str:
    str_list, start, count = [], "", 1
    for c in string:
        if not start:
            start = c
        elif start == c:
            count += 1
        else:
            str_list.append(str(count))
            str_list.append(start)
            count, start = 1, c
    return "".join([*str_list, str(count), start])


with open("in/d10.txt") as f:
    for l in (x.strip() for x in f):
        for _ in range(40):
            l = look_and_say(l)
        print("Part 1:", len(l))
        for _ in range(10):
            l = look_and_say(l)
        print("Part 2:", len(l))
