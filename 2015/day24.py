def find_qe(group_size: int, nums: tuple[int, ...], min_qe: list[int], qe: int = 1, counter: int = 0) -> int:
    if counter == group_size:
        min_qe[0] = qe
    else:
        for n in range(len(nums)):
            if (new_counter := counter + nums[n]) <= group_size and (new_qe := nums[n] * qe) < min_qe[0]:
                find_qe(group_size, nums[n + 1 :], min_qe, new_qe, new_counter)
    return min_qe[0]


with open("in/d24.txt") as f:
    numbers = tuple(map(int, reversed(f.read().split())))  # Largest nums first is much faster.
sums = sum(numbers)
print("Part 1:", find_qe(sums // 3, numbers, [1 << 40]))  # Store result in mutable list as "global" scope for recursion
print("Part 2:", find_qe(sums // 4, numbers, [1 << 40]))
