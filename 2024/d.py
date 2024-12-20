import sys
from os.path import isfile

import requests

year = 2024
print_input = True
max_rows = 168

if len(sys.argv) == 1:
    raise Exception("No day given")

day = int(sys.argv[1])
if not (1 <= day <= 25):
    raise Exception("Invalid date")

target_file = f"in/d{day:02}.txt"
if isfile(target_file) or isfile(target_file.replace(".txt", "t.txt")):
    raise Exception(f"File already exists: {target_file}")

with open(".env") as f:
    cookie = f.readline().rstrip()

"""Fetch example data"""
ex_result = requests.get(f"https://adventofcode.com/{year}/day/{day}", cookies={"session": cookie})
if not ex_result.ok:
    raise Exception(f"Request failed: {ex_result.status_code}, {ex_result.reason}, {ex_result.text}")

text = ex_result.text
start_pre = text.find("<pre>") + 5
end_pre = text.find("</pre>")

example_block = text[start_pre:end_pre].replace("<code>", "").replace("</code>", "")

with open(target_file.replace(".txt", "t.txt"), "wt") as f:
    f.write(example_block)

"""Fetch input"""
in_result = requests.get(f"https://adventofcode.com/{year}/day/{day}/input", cookies={"session": cookie})
if not in_result.ok:
    raise Exception(f"Request failed: {in_result.status_code}, {in_result.reason}, {in_result.text}")

with open(target_file, "wt") as f:
    f.write(in_result.text)

if print_input:
    for row in in_result.text.split("\n")[: max_rows + 1]:
        print(row)
