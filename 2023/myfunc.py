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
