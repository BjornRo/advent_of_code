import sys
from datetime import UTC, datetime
from os import makedirs
from os.path import isfile
from pathlib import Path

import requests

"""
File args: Empty or day [1-25] -> thisfile.py 24

If no file args given: Automatically fetches year and day IF december.
If day is given, the year specified below will be used!

Cookie is simply taken using your browser. Take the value of the cookie and store it
in a secret 'cookie_file'.
"""

year = 2020
print_input = True
max_rows = 168
cookie_keyname = "session"
cookie_file = ".env"

# Pads a '0' if it is only 1 digit. Replace for your desired output path+filenames.
example_suffix = "t"  # for example d21t.txt
input_file = "in/d{:02}.txt"
example_file = "in/d{:02}<#>.txt"


"""Do not touch"""
date = datetime.now(UTC)
if len(sys.argv) >= 2:
    day = int(sys.argv[1])
    if not (1 <= day <= 25):
        raise Exception(f"Invalid date, [1,25], given: {day}")
else:
    day = date.day
    year = date.year
    if date.month != 12:
        raise Exception("Cannot use this script other than december without any file arguments.")
    if not (1 <= day <= 25):
        raise Exception("Invalid day, use first argument for day")

if date < datetime(year=year, month=12, day=day, hour=5, tzinfo=UTC):
    raise Exception("Current day is not open yet!")

makedirs("in", exist_ok=True)
input_file = input_file.format(day)
example_file = example_file.format(day)
if isfile(input_file):
    raise Exception(f"File already exists: {input_file}")

with open(Path(__file__).parent.parent / cookie_file) as f:
    cookie = {cookie_keyname: f.read().strip()}


"""Fetch input"""
in_result = requests.get(f"https://adventofcode.com/{year}/day/{day}/input", cookies=cookie)
if not in_result.ok:
    raise Exception(f"Request failed: {in_result.status_code}, {in_result.reason}, {in_result.text}")

with open(input_file, "wt", newline="\n") as f:
    f.write(in_result.text)

if print_input:
    for row in in_result.text.split("\n")[: max_rows + 1]:
        print(row)

in_cols = in_result.text.index("\n")
in_rows = in_result.text.count("\n")

print(f"Input shape: Rows: {in_rows}, Cols: {in_cols}")


"""Fetch example data"""
with open(example_file.replace("<#>", example_suffix), "wt", newline="\n") as f:
    f.write("\n")
# ex_result = requests.get(f"https://adventofcode.com/{year}/day/{day}", cookies=cookie)
# if not ex_result.ok:
#     raise Exception(f"Request failed: {ex_result.status_code}, {ex_result.reason}, {ex_result.text}")

# text = ex_result.text

# if text.count("<pre>") > 1:
#     try:
#         res = text.lower().index("example:")
#     except:
#         raise Exception("Could not find example")
#     text = text[res + 8 :]

# for i in range(1, 11):
#     start_pre = text.find("<pre>") + 5
#     end_pre = text.find("</pre>")

#     example_block = re.sub(r"<.*?>", "", text[start_pre:end_pre])

#     example_cols = example_block.index("\n")
#     example_rows = example_block.count("\n")

#     example_block = example_block.replace("&gt;", ">").replace("&lt;", "<").replace("&amp;", "&").replace("&quot;", '"')

#     with open(example_file.replace("<#>", example_suffix * i), "wt", newline="\n") as f:
#         f.write(example_block)

#     try:
#         more_ex = text.lower().index("example:")
#         text = text[more_ex + 8 :]
#     except:
#         break


# print(f"Example shape: Rows: {example_rows}, Cols: {example_cols}")
