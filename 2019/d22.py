def egcd(a: int, b: int) -> tuple[int, int, int]:
    if a == 0:
        return (abs(b), 0, 1)
    g, y, x = egcd(b % a, a)
    return (g, x - (b // a) * y, y)


# def modinv(a: int, m: int):
#     g, x, y = egcd(a, m)
#     if g != 1:
#         raise Exception("modular inverse does not exist")
#     return x % m


def modinv(a: int, mod: int):
    return pow(a, -1, mod)


procedures = None
if procedures is None:
    with open("in/d22.txt") as f:
        procedures = f.read().splitlines()

card_index = 2020
shuffles = 3
len = 10007

# { 9316, 7033, 4750 }, exp: 7033

index = 2020
for raw_proc in procedures:
    match raw_proc.split():
        case "deal", "into", *_:
            index = len - 1 - index
        case "cut", value:
            index = (index - int(value)) % len
        case "deal", "with", *rest:
            value = int(rest[-1])
            index = modinv(value * index * shuffles, len)

print(index)
print(modinv(pow(index, shuffles, len), len))
print(pow(index, shuffles, len))
