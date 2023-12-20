import re

with open("in/d19.txt") as f:
    _workflows, _ratings = (x.split("\n") for x in f.read().split("\n\n"))
svenska = re.compile(r"([a-z])([><])(\d+):([a-zA-Z]+)|([a-zA-Z]+)")
workflows: dict[str, list[list[str]]] = {
    m[:t]: [[w for w in svenska.match(x).groups() if w] for x in m[t:][1:-1].split(",")]  # type: ignore
    for m in _workflows
    if (t := m.index("{"))
}
ratings = [{m[0]: int(m[1]) for m in (i.split("=") for i in r[1:-1].split(",") if i)} for r in _ratings if r]


def judgemental(rating: dict[str, int], subject: str) -> int:
    if subject == "A":
        return sum(rating.values())
    if subject != "R":
        for wf in workflows[subject]:
            match wf:
                case [xmas, "<", value, next_subject] if rating[xmas] < int(value):
                    return judgemental(rating, next_subject)
                case [xmas, ">", value, next_subject] if rating[xmas] > int(value):
                    return judgemental(rating, next_subject)
                case [next_subject]:
                    return judgemental(rating, next_subject)
    return 0


print("Part 1:", sum(judgemental(r, "in") for r in ratings))


# Part 2
def calc_branch(xmas_maxmin: dict[str, list[int]]) -> int:
    I, Ii, II, I_ = map(lambda x: x[1] - x[0] + 1, xmas_maxmin.values())
    return I * Ii * II * I_


def upd_dict_cpy(xmas_dict: dict[str, list[int]], key: str, index: int, val: str, offset: int) -> dict[str, list[int]]:
    new_dict = {k: v.copy() for k, v in xmas_dict.items()}
    new_dict[key][index] = int(val) + offset
    return new_dict


def judger(subject: list[list[str]], xmas_minmax: dict[str, list[int]]) -> int:
    p = lambda k, i, v, o: upd_dict_cpy(xmas_minmax, k, i, v, o)
    match subject[0]:
        case ["A"]:
            return calc_branch(xmas_minmax)
        case ["R"]:
            return 0
        case [xmas, ">", value, "A"]:
            return calc_branch(p(xmas, 0, value, 1)) + judger(subject[1:], p(xmas, 1, value, 0))
        case [xmas, "<", value, "A"]:
            return calc_branch(p(xmas, 1, value, -1)) + judger(subject[1:], p(xmas, 0, value, 0))
        case [xmas, ltgt, value, "R"]:
            return judger(subject[1:], p(xmas, ltgt == ">", value, 0))
        case [xmas, ">", value, new_subject]:
            return judger(workflows[new_subject], p(xmas, 0, value, 1)) + judger(subject[1:], p(xmas, 1, value, 0))
        case [xmas, "<", value, new_subject]:
            return judger(workflows[new_subject], p(xmas, 1, value, -1)) + judger(subject[1:], p(xmas, 0, value, 0))
    return judger(workflows[subject[0][0]], xmas_minmax)


print("Part 2:", judger(workflows["in"], {k: [1, 4000] for k in "xmas"}))
