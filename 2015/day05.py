def part1(s: str, vowels=set("aeiou"), vowel_count=0, twice=False):
    for i in range(len(s) - 1):
        ss = s[i : i + 2]
        if ss in {"ab", "cd", "pq", "xy"}:
            return False
        if not twice and ss[0] == ss[1]:
            twice = True
        if ss[1] in vowels:
            vowel_count += 1
    return vowel_count + (s[0] in vowels) >= 3 and twice


def part2(s: str):
    twice, between = False, s[len(s) - 3] == s[len(s) - 1]
    for i in range(len(s) - 3):
        if not between and s[i] == s[i + 2]:
            between = True
        if not twice:
            for j in range(i + 2, len(s) - 1):
                if s[i : i + 2] == s[j : j + 2]:
                    twice = True
                    break
        if between and twice:
            return True
    return False


with open("in/d5.txt") as f:
    total1 = total2 = 0
    for s in f:
        total1 += part1(s)
        total2 += part2(s)
    print("Part 1:", total1)
    print("Part 2:", total2)
