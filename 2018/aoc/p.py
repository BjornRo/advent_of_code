import re

with open("in/d04t.txt") as f:
    data = f.read()

data = "2611 units each with 28641 hit points with an attack that does 21 fire damage at initiative 2"
data = "1181 units each with 5833 hit points (weak to bludgeoning; immune to slashing, cold) with an attack that does 44 cold damage at initiative 6"
re.findall( r"(\d+)[a-z\s]+(\d+)[\w\s]+points(?:\s+\((.*?)\))?[a-z\s]+(\d+)\s(\w+)[a-z\s]+(\d+)", data)


re.findall(r"^(\d+)[a-z\s]+(\d+)[\w\s]+\(([a-z\s,;]+)\)[a-z\s]+(\d+) (\w+)[a-z\s]+(\d+)", data)
re.findall(r"^(\d+)\s+units\s+each\s+with\s+(\d+)\s+hit\s+points(?:\s+\((.*?)\))?\s+with\s+an\s+attack\s+that\s+does\s+(\d+)\s+(\w+)\s+damage\s+at\s+initiative\s+(\d+)", data)
