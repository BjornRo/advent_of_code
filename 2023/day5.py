import time

with open("d5.txt", "rt") as f:
    _seeds, _infile = f.read().replace(" map", "").split("\n", 1)
seeds: list[int] = [int(x) for x in _seeds.replace(":", "").split(" ")[1:]]
maps: list[list[list[int]]] = [
    [(lambda m: [m[0] - m[1], m[1], m[1] + m[2]])([int(y) for y in z.split(" ")]) for z in v.strip().split("\n")]
    for v in [x.split(":")[1] for x in _infile.strip("\n").split("\n" * 2)]
]


def to_to(seed: int, mapper: list[list[list[int]]]) -> int:
    for m in mapper:
        for dst, src, rng in m:
            if src <= seed <= rng:
                seed = dst + seed
                break
    return seed


# Part 1
if __name__ == "__main__":
    print("Part 1:", min(to_to(x, maps) for x in seeds))


# Part 2 - Brute-force and ignorance - Run with pypy for 30x speedup :)
def g(task: tuple[int, range]):
    start = time.time()
    print("Starting task", task[0])
    val = min(to_to(k, maps) for k in task[1])
    print(f"Finished task {task[0]}:", round(time.time() - start, 4), "sec, value:", val)
    return val


if __name__ == "__main__":
    from multiprocessing import Pool

    tasks = sorted((seeds[i : i + 2] for i in range(0, len(seeds) - 1, 2)), key=lambda x: x[1], reverse=True)
    new_tasks = tasks[len(tasks) // 2 :]
    for s, rng in tasks[: len(tasks) // 2]:
        new_tasks.append([s, rng // 4])
        new_tasks.append([s + rng // 4, rng // 4])
        new_tasks.append([s + rng // 2, rng // 4])

    start = time.time()
    tasks = (range(i, i + j + 1) for i, j in sorted(new_tasks, key=lambda x: x[1], reverse=True))

    with Pool(processes=6) as p:
        print("Final result part 2:", min(p.map(g, list(enumerate(tasks, 1)))))
    print("Total time elapsed:", round(time.time() - start, 4), "sec")
