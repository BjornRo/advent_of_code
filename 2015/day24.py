with open("in/d24.txt") as f:
    numbers = list(map(int, f.read().split()))


def find_qe(group_size: int, nums: list[int], qe: int = 1, counter: int = 0):
    if counter == group_size:
        return qe

    value = 1 << 64
    for n in range(len(nums)):
        if (new_counter := counter + nums[n]) <= group_size:
            value = min(find_qe(group_size, nums[n + 1 :], nums[n] * qe, new_counter), value)
    return value


group_size = sum(numbers)
print("Part 1:", find_qe(group_size // 3, numbers))
print("Part 2:", find_qe(group_size // 4, numbers))
