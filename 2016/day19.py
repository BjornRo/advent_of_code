from dataclasses import dataclass

with open("in/d19.txt") as f:
    stealing_philosophers = int(f.read().rstrip())


@dataclass
class LinkedPhilosopher:
    id: int
    next: "None | LinkedPhilosopher" = None


# start = LinkedPhilosopher(1)
# curr = start
# for i in range(2, stealing_philosophers + 1):
#     curr.next = LinkedPhilosopher(i)
#     curr = curr.next
# curr.next = start
# curr = start

# while True:
#     if curr.id == curr.next.id:  # type:ignore
#         print(curr.id)  # type:ignore
#         break
#     curr.next = curr.next.next  # type:ignore
#     curr = curr.next  # type:ignore


##
...

# 334690 too low
# 1004070 too low
#
# for i in range(1, 20):
#     stealing_philosophers = i
#     table = [*range(1, stealing_philosophers + 1)]
#     i = 0
#     while (t_len := len(table)) > 1:
#         popper = (i + t_len // 2) % t_len
#         # print(table, i, table[i])
#         # print("Index:", 1)
#         # print("At index:",  table[i])
#         # print("To Pop:",  popper)
#         # breakpoint()
#         table.pop(popper)
#         if popper > i:
#             i += 1
#         if i >= len(table):
#             i = 0
#     print(stealing_philosophers, table)

"""
1 [1]
2 [1]
3 [3]
4 [1]
5 [2]
6 [3]
7 [5]
8 [7]
9 [9]
"""

for stealing_philosophers in (range(3,10000)):
    start = LinkedPhilosopher(1)
    curr = start
    for i in range(2, stealing_philosophers + 1):
        curr.next = LinkedPhilosopher(i)
        curr = curr.next
    curr.next = start
    curr = start

    i = stealing_philosophers
    while True:
        if curr.id == curr.next.id:  # type:ignore
            if stealing_philosophers == curr.id:
                print(curr.id)
            # print(stealing_philosophers, curr.id)  # type:ignore
            break
        target = curr
        for _ in range(i // 2 - 1):
            target = target.next
        target.next = target.next.next  # type:ignore
        curr = curr.next  # type:ignore
        i -= 1
