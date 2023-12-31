from dataclasses import dataclass, field


@dataclass
class Shield:
    mana = 113
    ticks = 6
    curr_tick = 0

    def active(self) -> bool:
        self.curr_tick += 1
        return self.curr_tick != self.ticks


@dataclass
class Recharge:
    mana = 229
    ticks = 5
    curr_tick = 0

    def active(self) -> bool:
        self.curr_tick += 1
        return self.curr_tick != self.ticks


@dataclass
class Poison:
    dmg = 3
    mana = 173
    ticks = 6
    curr_tick = 0

    def tick(self) -> None | int:
        self.curr_tick += 1
        if self.curr_tick != self.ticks:
            return self.dmg


@dataclass
class Boss:
    hp: int
    attack: int
    curse: None | Poison = None

    def alive(self) -> bool:
        if c := self.curse:
            if dmg := c.tick():
                self.hp -= dmg
            else:
                self.curse = None
        return self.hp > 0

    def damage(self, dmg: int):
        self.hp -= dmg


@dataclass
class Character:
    hp: int
    mana: int
    shield = 0
    actives: list[Shield | Recharge] = field(default_factory=list)

    def damage(self, dmg: int):
        self.hp += self.shield - dmg

    def alive(self) -> bool:
        remaining = []
        while self.actives:
            c = self.actives.pop()
            res = c.active()
            match c:
                case Shield():
                    self.shield = 7 if res else 0
                case Recharge():
                    self.mana += 101 if res else 0
            if res:
                remaining.append(c)
        self.actives.extend(remaining)
        return self.hp > 0


with open("in/d22.txt") as f:
    hp, dmg = (int(x.split()[-1]) for x in f)

boss = Boss(hp=13, attack=8)
player = Character(hp=10, mana=250)

# Player turn
# Player casts Poison.
curse = Poison()
player.mana -= curse.mana
boss.curse = curse

# Boss turn
boss.alive()
player.alive()
player.hp -= boss.damage

# Player turn
boss.alive()
player.alive()
player.mana -= 53
boss.hp -= 4

# Boss turn
boss.alive()
player.alive()
