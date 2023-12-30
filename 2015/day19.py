import random
from collections import defaultdict

grammar, rev_list_grammar = defaultdict(list), []
with open("in/d19.txt") as f:
    _grammar, string = f.read().rstrip().split("\n\n")
    for k, v in (x.split(" => ") for x in _grammar.split("\n")):
        grammar[k].append(v)
        rev_list_grammar.append((v, k))


def context_full_grammar(string: str) -> int:
    distinct = set()
    for i in range(len(string) - 1):
        sub_string = string[i : i + 2]
        if sub_string in grammar:
            for prod in grammar[sub_string]:
                distinct.add(string[:i] + prod + string[i + 2 :])
        if (ss := sub_string[0]) in grammar:
            for prod in grammar[ss]:
                distinct.add(string[:i] + prod + string[i + 1 :])
        if (ss := sub_string[1]) in grammar:
            for prod in grammar[ss]:
                distinct.add(string[: i + 1] + prod + string[i + 2 :])
    return len(distinct)


print("Part 1:", context_full_grammar(string))


def context_cost_grammar(text: str) -> int:
    steps, lgram, last_value, new_text = 0, len(rev_list_grammar), 0, text
    while new_text != "e":
        for k, v in random.sample(rev_list_grammar, lgram):  # Otherwise infinite loop due to
            if sstep := new_text.count(k):  # deriving wrong path.
                steps += sstep
                new_text = new_text.replace(k, v)
        if (lx := len(new_text)) != last_value:
            last_value = lx
        else:  # Try again and hope the randomness solves it :), NICE! LOL
            new_text, steps = text, 0
    return steps


print("Part 2:", context_cost_grammar(string))
