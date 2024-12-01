import os

ignore = {"in", "mylib", "_zig_ver0_13_0"}

for item in os.listdir():
    if os.path.isfile(item) and item not in ignore:
        if not (".py" in item or ".zig" in item):
            os.remove(item)
