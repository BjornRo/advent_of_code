import json
import re


def del_red(jsdata: dict | list | int | str):
    if isinstance(jsdata, dict):
        if "red" in jsdata.values():
            return ""
        return {k: del_red(v) for k, v in jsdata.items()}
    elif isinstance(jsdata, list):
        return [del_red(i) for i in jsdata]
    return jsdata


with open("in/d12.txt") as f:
    string = f.read().strip()
    print("Part 1:", sum(map(int, re.findall(r"-?\d+", string))))
    print("Part 2:", sum(map(int, re.findall(r"-?\d+", json.dumps(del_red(json.loads(string)))))))
