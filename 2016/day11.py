def mopper(string: str) -> tuple:
    items = []
    for s in string.rstrip().split("a ")[1:]:
        s = s.split()
        items.append(s[0][0] + s[1][0])
    return tuple(items)


with open("in/d11.txt") as f:
    floors = tuple(mopper(s) if i != 3 else () for i, s in enumerate(f))
    print(floors)

# (('sg', 'sm', 'pg', 'pm'), ('tg', 'rg', 'rm', 'cg', 'cm'), ('tm',), ())
stack = []
while stack:
    pass
