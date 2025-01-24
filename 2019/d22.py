with open("in/d22.txt") as f:
    procedures = f.read().splitlines()

card_index = 2020
shuffles = 3
len = 10007

index = 0
for raw_proc in procedures:
    match raw_proc.split():
        case "deal", "into", *_:
            index = len - 1 - index
        case "cut", value:
            index = (index - int(value)) % len
        case "deal", "with", *rest:
            index = (index * int(rest[-1])) % len

print(index)
