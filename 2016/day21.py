with open("in/d21.txt") as f:
    scrambler = tuple(tuple(x.rstrip().split()) for x in f)

pw = list("abcdefgh")
pw = list("ecabd")
for i in scrambler:
    match i:
        case "swap", t, a, _, _, b:
            a, b = (int(a), int(b)) if t == "position" else (pw.index(a), pw.index(b))
            pw[a], pw[b] = pw[b], pw[a]
        case "rotate", lr, steps, _:
            steps = int(steps) * (1 if lr == "left" else -1)
            pw = pw[steps:] + pw[:steps]
        case "rotate", _, _, _, _, _, letter:
            steps = pw.index(letter)
            steps = -((steps + 1 + (1 if steps >= 4 else 0)) % len(pw))
            pw = pw[steps:] + pw[:steps]
        case "reverse", _, a, _, b:
            a, b = int(a), int(b)
            pw[a : b + 1] = pw[a : b + 1][::-1]
        case "move", _, a, _, _, b:
            pw.insert(int(b), pw.pop(int(a)))

print("".join(pw))

for i in scrambler[::-1]:
    match i:
        case "swap", t, a, _, _, b:
            a, b = (int(a), int(b)) if t == "position" else (pw.index(a), pw.index(b))
            pw[a], pw[b] = pw[b], pw[a]
        case "rotate", lr, steps, _:
            steps = int(steps) * (1 if lr != "left" else -1)  # Modified
            pw = pw[steps:] + pw[:steps]
        case "rotate", _, _, _, _, _, letter:
            steps = pw.index(letter)  # This part does not work.
            steps = (steps + 1 + (1 if steps >= 4 else 0)) % len(pw)
            pw = pw[steps:] + pw[:steps]
        case "reverse", _, a, _, b:
            a, b = int(a), int(b)
            pw[a : b + 1] = pw[a : b + 1][::-1]
        case "move", _, b, _, _, a:  # Modified
            pw.insert(int(b), pw.pop(int(a)))

print("".join(pw))
