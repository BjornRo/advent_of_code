import re
from copy import deepcopy as dc

svenska = re.compile(r"^([a-z])([><])(\d+):([a-zA-Z]+)|([a-zA-Z]+)")

with open("in/d19.txt") as f:
    _workflows, _ratings = (x.split("\n") for x in f.read().split("\n\n"))

workflows: dict[str, list[list[str]]] = {
    m[:x]: [[w for w in svenska.match(x).groups() if w] for x in m[x:][1:-1].split(",")]  # type: ignore
    for m in _workflows
    if (x := m.index("{"))
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


print(sum(judgemental(r, "in") for r in ratings))

# Part 2


def rtv(maxminlist: list[int]) -> int:
    return maxminlist[1] - maxminlist[0] + 1


def calc_branch(xmas_maxmin: dict[str, list[int]]) -> int:
    total = 1
    for x in map(rtv, xmas_maxmin.values()):
        total *= x
    return total


def judger(subject: str, xmas_minmax: dict[str, list[int]], wf_index=0):
    left_minmax = dc(xmas_minmax)
    right_minmax = dc(xmas_minmax)
    try:
        if_true, if_false = workflows[subject][wf_index : 2 + wf_index]
    except:
        print(subject)
        assert False
    match if_true, if_false:
        case [_, _, _, "R"], ["R"]:  # OK
            return 0
        case [_, _, _, "A"], ["A"]:  # OK
            return calc_branch(left_minmax)
        case [xmas, ">", value, "A"], ["R"]:  # OK
            left_minmax[xmas][0] = int(value) + 1
            return calc_branch(left_minmax)
        case [xmas, "<", value, "A"], ["R"]:  # OK
            left_minmax[xmas][1] = int(value) - 1
            return calc_branch(left_minmax)
        case [xmas, ">", value, "R"], ["A"]:  # OK
            right_minmax[xmas][1] = int(value)
            return calc_branch(right_minmax)
        case [xmas, "<", value, "R"], ["A"]:
            right_minmax[xmas][0] = int(value)
            return calc_branch(right_minmax)
        # Recursion pairs #
        ###################
        case [xmas, ">", value, "A"], _:  # OK
            left_minmax[xmas][0] = int(value) + 1
            right_minmax[xmas][1] = int(value)
            if len(if_false) == 4:
                return calc_branch(left_minmax) + judger(subject, right_minmax, wf_index + 1)
            return calc_branch(left_minmax) + judger(if_false[0], right_minmax, 0)
        case [xmas, "<", value, "A"], _:  # OK
            left_minmax[xmas][1] = int(value) - 1
            right_minmax[xmas][0] = int(value)
            if len(if_false) == 4:
                return calc_branch(left_minmax) + judger(subject, right_minmax, wf_index + 1)
            return calc_branch(left_minmax) + judger(if_false[0], right_minmax, 0)
        case [xmas, ">", value, "R"], _:
            right_minmax[xmas][1] = int(value)
            if len(if_false) == 4:
                return judger(subject, right_minmax, wf_index + 1)
            return judger(if_false[0], right_minmax, 0)
        case [xmas, "<", value, "R"], _:
            right_minmax[xmas][0] = int(value)
            if len(if_false) == 4:
                return judger(subject, right_minmax, wf_index + 1)
            return judger(if_false[0], right_minmax, 0)
        # Recursion pairs #
        ###################
        case [xmas, ">", value, new_subject], ["A"]:
            left_minmax[xmas][0] = int(value) + 1
            right_minmax[xmas][1] = int(value)
            return judger(new_subject, left_minmax, 0) + calc_branch(right_minmax)
        case [xmas, "<", value, new_subject], ["A"]:
            left_minmax[xmas][1] = int(value) - 1
            right_minmax[xmas][0] = int(value)
            return judger(new_subject, left_minmax, 0) + calc_branch(right_minmax)
        case [xmas, ">", value, new_subject], ["R"]:
            left_minmax[xmas][0] = int(value) + 1
            return judger(new_subject, left_minmax, 0)
        case [xmas, "<", value, new_subject], ["R"]:
            left_minmax[xmas][1] = int(value) - 1
            return judger(new_subject, left_minmax, 0)
        # Recursion pairs #
        ###################
        case [xmas, "<", value, new_subject], _:
            left_minmax[xmas][1] = int(value) - 1
            right_minmax[xmas][0] = int(value)
            if len(if_false) == 4:
                return judger(new_subject, left_minmax, 0) + judger(subject, right_minmax, wf_index + 1)
            return judger(new_subject, left_minmax, 0) + judger(if_false[0], right_minmax, 0)
        case [xmas, ">", value, new_subject], _:
            left_minmax[xmas][0] = int(value) + 1
            right_minmax[xmas][1] = int(value)
            if len(if_false) == 4:
                return judger(new_subject, left_minmax, 0) + judger(subject, right_minmax, wf_index + 1)
            return judger(new_subject, left_minmax, 0) + judger(if_false[0], right_minmax, 0)
    print(if_true, if_false)
    assert False


print("Part 2:", judger("in", {"x": [1, 4000], "m": [1, 4000], "a": [1, 4000], "s": [1, 4000]}, 0))
