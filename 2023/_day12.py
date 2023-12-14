import time
from itertools import product

# _infile = """
# ???.### 1,1,3
# .??..??...?##. 1,1,3
# ?#?#?#?#?#?#?#? 1,3,1,6
# ????.#...#... 4,1,1
# ????.######..#####. 1,6,5
# ?###???????? 3,2,1
# """.strip().split(
#     "\n"
# )
# infile = [[s, list(map(int, p.split(",")))] for s, p in [x.split(" ") for x in _infile]]


def valid(spring: str, records: list[int]) -> bool:
    total_count = []
    count = 0
    for s in spring:
        if s == ".":
            if count:
                total_count.append(count)
            count = 0
        else:
            count += 1
    if count:
        total_count.append(count)
    return records == total_count


def solver(spring: str, records: list[int]) -> int:
    val = 0
    spring_list = []
    qdot = "#."
    for ptup in product((True, False), repeat=spring.count("?")):
        ip = 0
        js = 0
        slen = len(spring)
        while js < slen:
            c = spring[js]
            if c == "?":
                c = qdot[ptup[ip]]
                ip += 1
            spring_list.append(c)
            js += 1
        val += valid("".join(spring_list), records)
        spring_list.clear()
    return val


def g(task: tuple[int, tuple[str, list[int]]]) -> int:
    start = time.time()
    print("Starting task", task[0])
    val = solver("?".join([task[1][0]] * 5), task[1][1] * 5)
    print(f"Finished task {task[0]}:", round(time.time() - start, 4), "sec, value:", val)
    return val


if __name__ == "__main__":
    from multiprocessing import Pool

    start = time.time()

    with open("d12.txt") as f:
        infile = [(s.strip(), list(map(int, r.split(",")))) for s, r in (x.split() for x in f if x.strip())]

    n = 0
    for s, r in infile:
        n += solver(s, r)
    print("Part 1:", n)

    with Pool(processes=8) as p:
        results = p.map(g, list(enumerate(infile, 1)))
    print("Final result part 2:", sum(results))
    print("Total time elapsed:", round(time.time() - start, 4), "sec")

# 7922
