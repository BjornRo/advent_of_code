from dataclasses import dataclass

with open("in/d19.txt") as f:
    stealing_philosophers = int(f.read().rstrip())


@dataclass
class LinkedPhilosopher:
    id: int
    next: "None | LinkedPhilosopher" = None


start = LinkedPhilosopher(1)
curr = start
for i in range(2, stealing_philosophers + 1):
    curr.next = LinkedPhilosopher(i)
    curr = curr.next
curr.next = start
curr = start

while True:
    if curr.id == curr.next.id:  # type:ignore
        print(curr.id)  # type:ignore
        break
    curr.next = curr.next.next  # type:ignore
    curr = curr.next  # type:ignore

x = stealing_philosophers
y = 3
for _ in range(1000):
    _y = y * 3
    if _y > x:
        print(x - y)
        break
    elif _y == x:
        print(_y)
        break
    y = _y
