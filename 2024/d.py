import os
import sys

import requests

if len(sys.argv) == 1:
    raise Exception("No day given")

day = int(sys.argv[1])
if not (1 <= day <= 25):
    raise Exception("Invalid date")

target_file = f"in/d{day:02}.txt"
if os.path.isfile(target_file):
    raise Exception(f"File already exists: {target_file}")

with open(".env") as f:
    cookie = f.readline().rstrip()

result = requests.get(f"https://adventofcode.com/2024/day/{day}/input", cookies={"session": cookie})
if not result.ok:
    raise Exception(f"Request failed: {result.status_code}, {result.reason}, {result.text}")

with open(f"in/d{day:02}.txt", "wt") as f:
    f.write(result.text)

result = requests.get(f"https://adventofcode.com/2024/day/{day}", cookies={"session": cookie})
if not result.ok:
    raise Exception(f"Request failed: {result.status_code}, {result.reason}, {result.text}")

text = result.text
start_pre = text.find("<pre>") + 5
end_pre = text.find("</pre>")

example_block = text[start_pre:end_pre].replace("<code>", "").replace("</code>", "")

with open(f"in/d{day:02}t.txt", "wt") as f:
    f.write(example_block)
