from math import sqrt


def divisors(n: int) -> list[int]:
    d1 = [i for i in range(1, int(sqrt(n)) + 1) if n % i == 0]
    return d1 + [n // d for d in d1 if n != d**2]


with open("in/d20.txt") as f:
    num = int(f.read().strip())

part1 = part2 = 0
for i in range(num // 50, num):
    divs = divisors(i)
    if not part1:
        if sum(divs) * 10 >= num:
            part1 = i
    elif not part2 and sum(d for d in divs if i // d <= 50) * 11 >= num:
        part2 = i
        break

print("Part 1:", part1)
print("Part 2:", part2)
