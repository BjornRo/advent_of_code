from dataclasses import dataclass

with open("in/d19.txt") as f:
    stealing_philosophers = int(f.read().rstrip())


@dataclass
class LinkedPhilosopher:
    id: int
    _next: "None | LinkedPhilosopher" = None

    @property
    def next(self) -> "LinkedPhilosopher":
        assert isinstance(self._next, LinkedPhilosopher)
        return self._next

    @next.setter
    def next(self, n: "LinkedPhilosopher") -> None:
        self._next = n


start = LinkedPhilosopher(1)
curr = start
for i in range(2, stealing_philosophers + 1):
    curr.next = LinkedPhilosopher(i)
    curr = curr.next
curr.next = start
curr = start

while curr.id != curr.next.id:
    curr.next = curr.next.next
    curr = curr.next
print("Part 1:", curr.id)

i = 3
while i < stealing_philosophers:
    i *= 3
if not (i := (stealing_philosophers - i // 3)):
    i = stealing_philosophers
print("Part 2:", i)
