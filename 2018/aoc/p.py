from collections import Counter

import numpy as np

with open("in/d01.txt") as f:
    Counter(np.diff([int(x.rstrip()) for x in f])).most_common()
