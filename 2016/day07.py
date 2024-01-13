import re

abber = lambda s: (tuple(x[1:-1] for x in re.findall(r"\[[a-z]+\]", s)), tuple(re.sub(r"\[\w+\]", ",", s).split(",")))
with open("in/d7.txt") as f:
    abbas = tuple(abber(x.rstrip()) for x in f)


def teeless(abba: str) -> bool:
    for i in range(len(abba) - 3):
        if abba[i : i + 2] == abba[i + 2 : i + 4][::-1] and abba[i] != abba[i + 1]:
            return True
    return False


def snooper(abbas: tuple[tuple[str, ...], tuple[str, ...]]):
    for sq_sqrt, retval in zip(abbas, (False, True)):
        for s in sq_sqrt:
            for i in range(len(s) - 3):
                if s[i : i + 2] == s[i + 2 : i + 4][::-1] and s[i] != s[i + 1]:
                    return retval
    return False


print(sum(snooper(a) for a in abbas))
