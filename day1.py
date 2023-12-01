with open("d1.txt", "rt") as f:
    infile = f.read().strip().split("\n")

def g(x: str):
    start = ""
    end = ""
    found = False
    for i in x:
        if i.isdigit():
            if not found:
                start = i
                found = True
            else:
                end = i
    if end == "":
        end = start
    return int(start+end)

m = {"one":"1","two":"2","three":"3","four":"4","five":"5","six": "6","seven":"7","eight":"8","nine":"9"}
def starter(x:str):
    for i in range(len(x)):
        for j in m:
            if j in x[:i]:
                return m[j]
        if x[i].isdigit():
            return x[i]
    return ""

def ender(x: str):
    x = x[::-1]
    for i in range(len(x)):
        for j in m:
            if j[::-1] in x[:i]:
                return m[j]
        if x[i].isdigit():
            return x[i]
    return ""

import time
def tot(x: str):
    return int(starter(x) + ender(x))

total = sum(map(g, infile))
def xx():
    start = time.time()
    print(sum(map(tot, infile)))
    print(time.time() - start)


