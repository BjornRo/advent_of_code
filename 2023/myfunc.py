def timefunc(iterations: int = 0):
    import time
    from functools import wraps

    def decorator(f):
        @wraps(f)
        def timeit_wrapper(*args, **kwargs):
            start, result, _iters = time.perf_counter(), None, iterations + 1
            for _ in range(_iters):
                result = f(*args, **kwargs)
            print(f"Fn {f.__name__}{args} {kwargs}, Avg: {(time.perf_counter() - start) / _iters:.5f} secs")
            return result

        return timeit_wrapper

    return decorator


def egcd(a: int, b: int) -> tuple[int, int, int]:
    def _egcd(au: int, av: int, a: int, b: int, bu: int, bv: int):
        while a % b != 0 and b % a != 0:
            if a <= b:
                a, b, au, av, bu, bv = b - a, a, bu - au, bv - av, au, av
            else:
                a, b, au, av, bu, bv = a - b, b, au - bu, av - bv, bu, bv
        return (a, au, av) if a <= b else (b, bu, bv)

    return _egcd(1, 0, a, b, 0, 1)


def mod_inverse(a: int, m: int) -> int:
    gcd, x, _ = egcd(a, m)
    if gcd == 1:
        return x % m
    raise Exception("ModInv does not exist")


def crt(moduli: list | tuple, remainders: list | tuple):
    if len(moduli) == len(remainders):
        result, product = 0, 1
        for m in moduli:
            product *= m

        for mi, ai in zip(moduli, remainders):
            bi = product // mi
            result += ai * mod_inverse(bi, mi) * bi
        return result % product
    raise ValueError("Input differs in length")
