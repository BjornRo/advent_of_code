def g(row: list[int]) -> int:
    return row[-1] + g([y - x for x, y in zip(row, row[1:])]) if any(row) else 0

for w in enumerate(zip(*((g(k), g(k[::-1])) for k in (list(map(int, x.split(" "))) for x in open("d9.txt"))))):
    print(f"Part {w[0]+1}:", sum(w[1]))
