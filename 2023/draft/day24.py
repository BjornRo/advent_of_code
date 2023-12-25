Xyz, Delta = tuple[int, int, int], tuple[int, int, int]
Isboll = tuple[Xyz, Delta]
# def is_parallel(a: Isboll, b: Isboll, ignore_z=True, precision=10) -> bool:
#     da, db = (a[1][:2], b[1][:2]) if ignore_z else (a[1], b[1])
#     dot = dot_prod(da, db)
#     len_a = vec_len(da)
#     len_b = vec_len(db)
#     return round(abs(dot / (len_a * len_b)), precision) == 1.0


def cross_position(a: Isboll, b: Isboll, vec2=True) -> tuple[float, ...]:
    # Assumes non parallel and for vec3, is coplanar
    if vec2:
        pos_a1, da = a[0][:2], a[1][:2]
        pos_b1, db = b[0][:2], b[1][:2]
        pos_a2 = tuple(posi + deltai for posi, deltai in zip(pos_a1, da))
        pos_b2 = tuple(posi + deltai for posi, deltai in zip(pos_b1, db))
        stack = (pos_a1, pos_a2, pos_b1, pos_b2)
        homo = tuple((*x, 1) for x in stack)
        l1 = cross_prod_vec3(homo[0], homo[1])
        l2 = cross_prod_vec3(homo[2], homo[3])
        x, y, z = cross_prod_vec3(l1, l2)
        return x / z, y / z
    pos_a, da = a
    pos_b, db = b
    vec_ab = sub_vec3(pos_a, pos_b)
    vec_orthogonal = cross_prod_vec3(da, db)
    num = dot_prod(cross_prod_vec3(vec_ab, db), vec_orthogonal)
    denom = norm_vec(vec_orthogonal) ** 2
    vec_scaled = mul_vec(num / denom, da)
    return add_vec(pos_a, vec_scaled)


sub_vec = lambda u, v: tuple(vi - ui for vi, ui in zip(v, u))
cross_prod_vec3 = lambda u, v: (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
dot_prod = lambda u, v: sum(ui * vi for ui, vi in zip(u, v))
norm_vec = lambda u: math.sqrt(sum(map(lambda x: x * x, u)))
mul_vec = lambda s, u: tuple(round(s * ui, 10) for ui in u)
div_vec = lambda s, u: tuple(round(s / ui, 10) for ui in u)
add_vec = lambda u, v: tuple(ui + vi for ui, vi in zip(u, v))


def intersects(a: Isboll, b: Isboll, vec2=True) -> bool:
    if vec2:
        pos_a, da = a[0][:2], a[1][:2]
        pos_b, db = b[0][:2], b[1][:2]
        if (det := db[0] * da[1] - db[1] * da[0]) != 0:  # Linear dependent vectors equals zero.
            dx = pos_b[0] - pos_a[0]
            dy = pos_b[1] - pos_a[1]
            u = (dy * db[0] - dx * db[1]) / det
            v = (dy * da[0] - dx * da[1]) / det
            return u >= 0 and v >= 0
    else:
        pos_a, da = a
        pos_b, db = b

        denom = norm_vec(da) * norm_vec(db)
        cos_theta = dot_prod(da, db) / denom
        similarity = abs(min(1, max(cos_theta, -1)))
        if math.isclose(similarity, 1):
            return False

        pos_aa = add_vec(pos_a, da)
        pos_bb = add_vec(pos_b, db)
        stack = (pos_a, pos_aa, pos_b, pos_bb)
