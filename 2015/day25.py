import re

with open("in/d25.txt") as f:
    row, col = map(int, re.findall(r"\d+", f.read().strip()))

