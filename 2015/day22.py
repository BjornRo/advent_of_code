from copy import deepcopy
from dataclasses import dataclass, field


def main():
    with open("in/d22.txt") as f:
        hp, dmg = (int(x.split()[-1]) for x in f)
    print("Part 1:", land_of_magic(hp, dmg))
    print("Part 2:", land_of_magic(hp, dmg, True))


def land_of_magic(boss_hp: int, boss_attack: int, part2: bool = False):
    stack, min_mana = [(Character(hp=50, mana=500), Boss(hp=boss_hp, attack=boss_attack))], 1 << 32
    while stack:
        player, boss = stack.pop()

        if part2:
            player.hp -= 1
        if player.mana_used >= min_mana or player.hp <= 0:
            continue

        # Player turn
        player.turn()
        boss.turn()

        if player.mana < 53:
            # Boss turn
            player.turn()
            boss.turn()
            player.damage(boss.attack)
            stack.append((player, boss))
            continue

        for move in MagicMissile(), Drain(), Shield(), Poison(), Recharge():
            cplayer, cboss = deepcopy(player), deepcopy(boss)
            if cplayer.mana_use(move.mana):
                match move:
                    case MagicMissile():
                        cboss.damage(move.dmg)
                    case Drain():
                        cboss.damage(move.dmg)
                        cplayer.hp += move.heal
                    case Shield() | Recharge(): # Might need to check if active exist? Works anyways.
                        cplayer.actives.append(move)
                    case Poison():
                        cboss.curse = move
                if cboss.hp <= 0:
                    min_mana = min(cplayer.mana_used, min_mana)
                    continue
                # Boss turn
                cplayer.turn()
                cboss.turn()
                cplayer.damage(cboss.attack)
                if cplayer.hp > 0:
                    stack.append((cplayer, cboss))
    return min_mana


@dataclass
class MagicMissile:
    mana = 53
    dmg = 4


@dataclass
class Drain:
    mana = 73
    dmg = 2
    heal = 2


@dataclass
class Shield:
    mana = 113
    ticks = 6
    curr_tick = 0

    def active(self) -> bool:
        self.curr_tick += 1
        return self.curr_tick <= self.ticks


@dataclass
class Recharge:
    mana = 229
    ticks = 5
    curr_tick = 0

    def active(self) -> bool:
        self.curr_tick += 1
        return self.curr_tick <= self.ticks


@dataclass
class Poison:
    dmg = 3
    mana = 173
    ticks = 6
    curr_tick = 0

    def tick(self) -> None | int:
        self.curr_tick += 1
        if self.curr_tick <= self.ticks:
            return self.dmg


@dataclass
class Boss:
    hp: int
    attack: int
    curse: None | Poison = None

    def turn(self) -> bool:
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
    mana_used = 0
    actives: list[Shield | Recharge] = field(default_factory=list)

    def damage(self, dmg: int):
        self.hp += self.shield - dmg

    def turn(self) -> bool:
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

    def mana_use(self, mana: int) -> bool:
        if self.mana >= mana:
            self.mana_used += mana
            self.mana -= mana
            return True
        return False


main()
