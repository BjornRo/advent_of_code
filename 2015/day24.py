with open("in/d24.txt") as f:
    numbers = list(map(int, f.read().split()))


def find_qe(group_size: int, nums: list[int], min_qe: list[int], qe: int = 1, counter: int = 0) -> int:
    if counter == group_size:
        if qe < min_qe[0]:
            min_qe[0] = qe
        return min_qe[0]

    for n in range(len(nums)):
        if (new_counter := counter + nums[n]) <= group_size and (new_qe := nums[n] * qe) < min_qe[0]:
            find_qe(group_size, nums[n + 1 :], min_qe, new_qe, new_counter)
    return min_qe[0]


group_size = sum(numbers)
print("Part 1:", find_qe(group_size // 3, numbers, [1 << 64]))
print("Part 2:", find_qe(group_size // 4, numbers, [1 << 64]))
