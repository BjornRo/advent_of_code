import re

svenska = re.compile(r"^([a-z])([><])(\d+):([a-zA-Z]+)|([a-zA-Z]+)")

with open("in/e19.txt") as f:
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

"""
px{a<2006:qkq,m>2090:A,rfg}
pv{a>1716:R,A}
lnx{m>1548:A,A}
rfg{s<537:gd,x>2440:R,A}
qs{s>3448:A,lnx}
qkq{x<1416:A,crn}
crn{x>2662:A,R}
in{s<1351:px,qqz}
qqz{s>2770:qs,m<1801:hdj,R}
gd{a>3333:R,R}
hdj{m>838:A,pv}

{x=787,m=2655,a=1222,s=2876}
{x=1679,m=44,a=2067,s=496}
{x=2036,m=264,a=79,s=2244}
{x=2461,m=1339,a=466,s=291}
{x=2127,m=1623,a=2188,s=1013}
"""

keys = list(workflows)
wf = workflows[keys[0]]
# [['a', '<', '2006', 'qkq'], ['m', '>', '2090', 'A'], ['rfg']]

from collections import defaultdict
from copy import deepcopy

nworkflows = deepcopy(workflows)
for k, v in nworkflows.items():
    pass


def branch_flattener(key: str, value: list[list[str]]):
    for i, item in enumerate(value):
        # ['rfg'] item
        match item:
            case ["A", "R"]:
                continue
            case [subject]:
                value
        break


"""
qkq{x<1416:A,crn}
crn{x>2662:A,R}
"""


def djudgemental(subject: str, wf_index=0) -> int:
    try:
        if_true, if_false = workflows[subject][wf_index : 2 + wf_index]
    except:
        print(subject)
        assert False
    match if_true, if_false:
        case [_, _, _, "A"], ["A"]:
            return 4000
        case [_, _, _, "R"], ["R"]:
            return 0
        case [_, ">", value, "A"], ["R"]:
            return 4000 - int(value)
        case [_, "<", value, "A"], ["R"]:
            return int(value) - 1
        case [_, ">", value, "R"], ["A"]:
            return int(value)
        case [_, "<", value, "R"], ["A"]:
            return 4000 - int(value) + 1
        # Recursion pairs #
        ###################
        case [_, ">", value, "A"], _:  # xxx{x>2662:A , x>2662:R , R}
            # value = 4000>3999 -> 4000-value
            distinct = 4000 - int(value)
            if len(if_false) == 4:
                return distinct * djudgemental(subject, wf_index + 1)
            return distinct * djudgemental(if_false[0], 0)
        case [_, "<", value, "A"], _:  # m>2662:A
            # value = 1<2 -> value-1
            distinct = int(value) - 1
            if len(if_false) == 4:
                return distinct * djudgemental(subject, wf_index + 1)
            return distinct * djudgemental(if_false[0], 0)
        case [_, ">", value, "R"], _:  # m>2662:A
            # 2 > 2 -> If value is 2, then two solution exists.
            distinct = int(value)
            if len(if_false) == 4:
                return distinct * djudgemental(subject, wf_index + 1)
            return distinct * djudgemental(if_false[0], 0)
        case [_, "<", value, "R"], _:
            # 3999 < 4000
            distinct = int(value) - 1
            if len(if_false) == 4:
                return distinct * djudgemental(subject, wf_index + 1)
            return distinct * djudgemental(if_false[0], 0)
        # Recursion pairs #
        ###################
        case [_, ">", value, new_subject], ["A"]:
            # 4000>3999
            distinct = int(value)
            return distinct * djudgemental(new_subject, 0)
        case [_, "<", value, new_subject], ["A"]:  # m>2662:A
            distinct = 4000 - int(value) + 1
            return distinct * djudgemental(new_subject, 0)
        case [_, ">", value, new_subject], ["R"]:
            # 4000 > 4000
            distinct = 4000 - int(value)
            return distinct * djudgemental(new_subject, 0)
        case [_, "<", value, new_subject], ["R"]:  # m>2662:A
            #
            distinct = int(value) - 1
            return distinct * djudgemental(new_subject, 0)
        # Recursion pairs #
        ###################
        case [_, _, value, new_subject], _:  # m>2662:A
            print(if_true, if_false)
            if len(if_false) == 4:
                return djudgemental(new_subject, 0) * djudgemental(subject, wf_index + 1)
            return djudgemental(new_subject, 0) * djudgemental(if_false[0], 0)
    print(if_true, if_false)
    assert False


# 167409079868000
djudgemental("qkq", 0)

# Subject: crn
# crn{x>2662:A,R}
# crn{x>2662:A,A}

# crn{x>2662:R,m>2662:A,R}
# crn{x>2662:qs,m>2662:A,R}

# crn{x>2662:A,m>2662:A,R}

# crn{x>2662:A,foo}
# foo{x>1:R,A}

# print(sum(djudgemental(r, "in") for r in ratings))
