from copy import deepcopy
from dataclasses import dataclass, field


def main():
    with open("in/d22.txt") as f:
        hp, dmg = (int(x.split()[-1]) for x in f)
    print(land_of_magic(hp, dmg))


# 1295, 1182 too high


def land_of_magic(boss_hp: int, boss_attack: int):
    min_mana = 1 << 32
    stack = [(Character(hp=50, mana=500), Boss(hp=boss_hp, attack=boss_attack))]
    while stack:
        player, boss = stack.pop()

        if player.mana_used >= min_mana or player.hp <= 0:
            continue

        player.turn()
        boss.turn()
        if boss.hp <= 0:
            min_mana = min(player.mana_used, min_mana)
            continue

        if player.mana < 53:
            player.turn()
            boss.turn()
            player.damage(boss.attack)
            stack.append((player, boss))
            continue

        for move in MagicMissile(), Drain(), Shield(), Poison(), Recharge():
            cplayer, cboss = deepcopy(player), deepcopy(boss)
            match move:
                case MagicMissile():
                    if not cplayer.mana_use(move.mana):
                        continue
                    cboss.damage(move.dmg)
                case Drain():
                    if not cplayer.mana_use(move.mana):
                        continue
                    cboss.damage(move.dmg)
                    cplayer.hp += move.heal
                case Shield():
                    if move in cplayer.actives or not cplayer.mana_use(move.mana):
                        continue
                    cplayer.actives.append(move)
                case Poison():
                    if cboss.curse is not None or not cplayer.mana_use(move.mana):
                        continue
                    cboss.curse = move
                case Recharge():
                    if move in cplayer.actives or not cplayer.mana_use(move.mana):
                        continue
                    cplayer.actives.append(move)
            if cboss.hp <= 0:
                min_mana = min(cplayer.mana_used, min_mana)
                continue
            cplayer.turn()
            cboss.turn()
            cplayer.damage(cboss.attack)
            if player.hp > 0:
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

# # P
# boss.turn()
# player.turn()
# recharge = Recharge()
# if recharge not in player.actives and player.mana_use(recharge.mana):
#     player.actives.append(recharge)

# # P
# boss.turn()
# player.turn()
# shield = Shield()
# if shield not in player.actives and player.mana_use(shield.mana):
#     player.actives.append(shield)


# # P
# boss.turn()
# player.turn()
# drain = Drain()
# if player.mana_use(drain.mana):
#     player.hp += drain.heal
#     boss.damage(drain.damage)
# # P
# boss.turn()
# player.turn()
# poison = Poison()
# if boss.curse is None and player.mana_use(poison.mana):
#     boss.curse = poison

# # P
# boss.turn()
# player.turn()
# magicmissile = MagicMissile()
# if player.mana_use(magicmissile.mana):
#     boss.damage(magicmissile.dmg)
