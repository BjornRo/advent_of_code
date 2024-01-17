with open("in/d22.txt") as f:
    f.readline()
    f.readline()
    fs = [x.rstrip().rsplit("/", 1)[1].replace("node-x", "").replace("-y", " ").split() for x in f]
