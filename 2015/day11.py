def valid_pw(pw: bytes) -> bool:  # "ilo" = (105,108,111)
    if (blen := len(pw)) == 8:
        if not (pw[blen - 2] in {105, 108, 111} or pw[blen - 1] in {105, 108, 111}):
            asc, twice = pw[blen - 1] - pw[blen - 2] == 1 and pw[blen - 2] - pw[blen - 3] == 1, pw[0] == pw[1]
            flip = twice
            for i in range(blen - 2):
                if pw[i] in {105, 108, 111}:
                    return False
                if not asc and pw[i + 2] - pw[i + 1] == 1 and pw[i + 1] - pw[i] == 1:
                    asc = True
                if not flip and pw[i + 1] == pw[i + 2]:
                    twice += 1
                    flip = True
                elif flip:
                    flip = False
            return asc and twice >= 2
    return False


def pw_generator(old_pw: str, skip=False):  # a:97, z:122
    pw, last = bytearray(old_pw.encode()), len(old_pw) - 1
    assert last + 1 == 8
    while not valid_pw(pw) or skip:
        skip = False
        pw[last] += 1
        if not (97 <= pw[last] <= 122):  # We are outside the range
            pw[last] = 97  # Reset last index to "a"
            pw[last - 1] += 1  # Overflow to next
            for j in range(last - 1, -1, -1):
                if 97 <= pw[j] <= 122:
                    break
                if j != 0:
                    pw[j - 1] += 1
                pw[j] = 97
    return pw.decode()


with open("in/d11.txt") as f:
    l = f.read().rstrip()
new_pw = pw_generator(l)
print("Part 1:", new_pw)
print("Part 2:", pw_generator(new_pw, True))
