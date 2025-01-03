import re

with open("in/d04t.txt") as f:
    data = f.read()


re.findall(r"\[([0-9\-\s:]+)\].+(#\d+|falls|wakes)", data)