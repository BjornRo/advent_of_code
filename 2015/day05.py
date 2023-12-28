VOWELS = set("aeiou")


def part1(s: str):
    vowel_count, twice = s[0] in VOWELS, False
    for i in range(len(s) - 1):
        ss = s[i : i + 2]
        if ss in {"ab", "cd", "pq", "xy"}:
            vowel_count = 0
            break
        if not twice and ss[0] == ss[1]:
            twice = True
        if ss[1] in VOWELS:
            vowel_count += 1
    return vowel_count >= 3 and twice


def part2(s: str):
    for i in range(len(s) - 3):
        for j in range(i + 2, len(s) - 1):
            if s[i : i + 2] == s[j : j + 2]:
                for i in range(len(s) - 2):
                    if s[i] == s[i + 2]:
                        return True
    return False


with open("in/d5.txt") as f:
    total1 = total2 = 0
    for s in f:
        total1 += part1(s)
        total2 += part2(s)
    print("Part 1:", total1)
    print("Part 2:", total2)
