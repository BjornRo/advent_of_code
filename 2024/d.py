import sys
from os.path import isfile

import requests

year = 2024
print_input = True
max_rows = 168
cookie_keyname = "session"

# Pads a '0' if it is only 1 digit.
input_file = "in/d{:02}.txt"
example_file = "in/d{:02}t.txt"

if len(sys.argv) == 1:
    raise Exception("No day given")

day = int(sys.argv[1])
if not (1 <= day <= 25):
    raise Exception("Invalid date")

input_file = input_file.format(day)
example_file = example_file.format(day)
if isfile(input_file) or isfile(example_file):
    raise Exception(f"File already exists: {input_file} |or| {example_file}")

with open(".env") as f:
    cookie = {cookie_keyname: f.readline().rstrip()}

"""Fetch example data"""
ex_result = requests.get(f"https://adventofcode.com/{year}/day/{day}", cookies=cookie)
if not ex_result.ok:
    raise Exception(f"Request failed: {ex_result.status_code}, {ex_result.reason}, {ex_result.text}")

text = ex_result.text
start_pre = text.find("<pre>") + 5
end_pre = text.find("</pre>")

example_block = text[start_pre:end_pre].replace("<code>", "").replace("</code>", "")

with open(example_file, "wt") as f:
    f.write(example_block)

"""Fetch input"""
in_result = requests.get(f"https://adventofcode.com/{year}/day/{day}/input", cookies=cookie)
if not in_result.ok:
    raise Exception(f"Request failed: {in_result.status_code}, {in_result.reason}, {in_result.text}")

with open(input_file, "wt") as f:
    f.write(in_result.text)

if print_input:
    for row in in_result.text.split("\n")[: max_rows + 1]:
        print(row)
