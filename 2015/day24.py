def find_qe(group_size: int, nums: tuple[int, ...], min_qe: list[int], qe: int = 1, total: int = 0) -> int:
    if total == group_size:
        min_qe[0] = qe
    else:
        for i, n in enumerate(nums, 1):
            if (new_qe := n * qe) < min_qe[0] and (new_total := total + n) <= group_size:
                find_qe(group_size, nums[i:], min_qe, new_qe, new_total)
    return min_qe[0]


with open("in/d24.txt") as f:
    numbers = tuple(map(int, reversed(f.read().split())))  # Largest nums first is much faster.
nsums = sum(numbers)
print("Part 1:", find_qe(nsums // 3, numbers, [1 << 40]))  # Store result in mutable list as "global" scope
print("Part 2:", find_qe(nsums // 4, numbers, [1 << 40]))
