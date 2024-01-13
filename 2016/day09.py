import math
import re

with open("in/d9.txt") as f:
    compress = f.read().strip()
MAX_LEN = len(compress)

data, start_paren, total, i = "", False, 0, 0
while i < MAX_LEN:
    if compress[i] == ")":
        (x, y), data, start_paren = map(int, data.split("x")), "", False
        total += x * y
        i += x
    elif compress[i] == "(":
        start_paren = True
    elif start_paren:
        data += compress[i]
    else:
        total += 1
    i += 1
print("Part 1", total)

# Part 2
"""
too high
6394179272413584371233021013587138364809020058188545931070041119
355846114923614305762929274246533676891283910454730772182230222908
9470304523840692720413143602881456519954628830256965882418157333527
3669286281690265424342952237014251830568969323525437960061227180899
1671309647962352115551189195369055538685035410631899501125923607722
5739120090590472847691651045704654840102208707279500754895760470835
20000000000000000000000000000000000000000008152601754159

(27x12)(20x12)(13x14)(7x10)(1x12)A
12*12*14*10*12 * (A) = 241920
Parse len of 27(first), then "collapse"


(25x3)(3x3)ABC(2x3)XY(5x2)PQRSTX(18x9)(3x2)TWO(5x7)SEVEN
445 long
"""
data, start_paren, total, i = "", False, 0, 0
while i < MAX_LEN:
    if compress[i] == ")":
        (x, y), data, start_paren = map(int, data.split("x")), "", False
        total += math.prod(int(c.split("x")[1]) for c in re.findall(r"\(([x0-9]+)\)", compress[i + 1 : i + x + 1])) * y
        i += x
    elif compress[i] == "(":
        start_paren = True
    elif start_paren:
        data += compress[i]
    else:
        total += 1
    i += 1
print(total)
