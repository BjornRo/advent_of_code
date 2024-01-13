import re

abber = lambda s: (tuple(x[1:-1] for x in re.findall(r"\[[a-z]+\]", s)), tuple(re.sub(r"\[\w+\]", ",", s).split(",")))
with open("in/d7.txt") as f:
    abbas = tuple(abber(x.rstrip()) for x in f)


def snooper(abbas: tuple[tuple[str, ...], tuple[str, ...]]) -> bool:
    for sq_sqrt, retval in zip(abbas, (False, True)):
        for s in sq_sqrt:
            for i in range(len(s) - 3):
                if s[i : i + 2] == s[i + 2 : i + 4][::-1] and s[i] != s[i + 1]:
                    return retval
    return False


def listenor(sq: tuple[str, ...], sqrt: tuple[str, ...]) -> bool:
    for s in sq:
        for i in range(len(s) - 2):
            a, b, c = s[i : i + 3]
            if a == c and a != b:
                t = b + a + b
                for ss in sqrt:
                    if t in ss:
                        return True
    return False


print("Part 1:", sum(snooper(a) for a in abbas))
print("Part 2:", sum(listenor(*a) for a in abbas))
