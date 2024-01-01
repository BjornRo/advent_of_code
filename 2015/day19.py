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
            distinct.update(string[:i] + prod + string[i + 2 :] for prod in grammar[sub_string])
        for j, s in enumerate(sub_string, i):
            if s in grammar:
                distinct.update(string[:j] + prod + string[j + 1 :] for prod in grammar[s])
    return len(distinct)


print("Part 1:", context_full_grammar(string))


def context_cost_grammar(text: str) -> int:
    steps, lgram, new_text = 0, len(rev_list_grammar), text
    while new_text != "e":
        reset = True
        for k, v in random.sample(rev_list_grammar, lgram):  # Otherwise infinite loop due to
            if sstep := new_text.count(k):  # deriving wrong path.
                steps += sstep
                new_text, reset = new_text.replace(k, v), False
        if reset:  # Try again and hope the randomness solves it :), NICE! LOL
            new_text, steps = text, 0
    return steps


print("Part 2:", context_cost_grammar(string))
