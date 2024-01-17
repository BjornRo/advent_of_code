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
for i in range(1,20):
    stealing_philosophers = i
    table = [*range(1, stealing_philosophers + 1)]
    i = 0
    while (t_len := len(table)) > 1:
        popper = (i + t_len // 2) % t_len
        # print(table, i, table[i])
        # print("Index:", 1)
        # print("At index:",  table[i])
        # print("To Pop:",  popper)
        # breakpoint()
        table.pop(popper)
        if popper > i:
            i += 1
        if i >= len(table):
            i = 0
    print(stealing_philosophers, table)
