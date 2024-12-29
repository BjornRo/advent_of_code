with open("in/d09.txt") as f:
    data = f.read().rstrip()


def canceled(stream: str):
    total = 0
    total_canceled = 0
    cancel_next = False
    is_group = stream[0] == "{"

    group: list[str] = []
    for i in stream:
        if is_group:
            match i:
                case "{":
                    group.append(i)
                case "}":
                    if not cancel_next:
                        total += len(group)
                    cancel_next = False
                    group.pop()
                case "<":
                    is_group = False
                case ">":
                    cancel_next = False
        else:
            match i:
                case "!":
                    cancel_next = not cancel_next
                case ">":
                    if not cancel_next:
                        is_group = True
                    cancel_next = False
                case _:
                    if not cancel_next:
                        total_canceled += 1
                    cancel_next = False
    return total, total_canceled


p1, p2 = canceled(data)
print(f"Part 1: {p1}")
print(f"Part 2: {p2}")
