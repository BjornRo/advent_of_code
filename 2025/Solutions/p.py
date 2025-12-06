with open("in/d06t.txt") as f:
    d = f.read().strip()

for i in list(map(lambda x: "".join(x),(zip(*d.split("\n"))))):
    print(list(i))