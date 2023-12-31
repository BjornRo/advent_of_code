from dataclasses import dataclass, field


@dataclass
class Spell:
    dmg: int
    mana: int
    ticks: int
    curr_tick = 0

    def tick(self) -> None | int:
        self.curr_tick += 1
        if self.curr_tick != self.ticks:
            return self.dmg


@dataclass
class Boss:
    hp: int
    curse: list[Spell] = field(default_factory=list)

    def alive(self) -> bool:
        remaining = []
        while self.curse:
            c = self.curse.pop()
            if dmg := c.tick():
                self.hp -= dmg
                remaining.append(c)
        self.curse.extend(remaining)
        return self.hp > 0

@dataclass
class Character:
    hp: int
    shield = 0

with open("in/d22.txt") as f:
    hp, dmg = (int(x.split()[-1]) for x in f)
