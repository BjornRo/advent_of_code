Xyz, Delta = tuple[int, int, int], tuple[int, int, int]
Isboll = tuple[Xyz, Delta]
# def is_parallel(a: Isboll, b: Isboll, ignore_z=True, precision=10) -> bool:
#     da, db = (a[1][:2], b[1][:2]) if ignore_z else (a[1], b[1])
#     dot = dot_prod(da, db)
#     len_a = vec_len(da)
#     len_b = vec_len(db)
#     return round(abs(dot / (len_a * len_b)), precision) == 1.0

Vec3 = list[int] | tuple[int, ...] | tuple[int, int, int]


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


def cross_position(a: tuple[Vec3, Vec3], b: tuple[Vec3, Vec3]) -> tuple[float, ...]:
    pa1, da, pb1, db = a[0][:2], a[1], b[0][:2], b[1]  # Zip will take the shortest
    pa2, pb2 = (pi + di for pi, di in zip(pa1, da)), (pi + di for pi, di in zip(pb1, db))
    ha, hb, hc, hd = ((*x, 1) for x in (pa1, pa2, pb1, pb2))
    x, y, z = cross_vec3(cross_vec3(ha, hb), cross_vec3(hc, hd))
    return x / z, y / z


def intersect(pos_a: list[int], da: list[int], pos_b: list[int], db: list[int]) -> bool:
    if (det := db[0] * da[1] - db[1] * da[0]) == 0:
        return False
    dx = pos_b[0] - pos_a[0]
    dy = pos_b[1] - pos_a[1]
    u = dy * db[0] - dx * db[1] / det
    v = dy * da[0] - dx * da[1] / det
    return u >= 0 and v >= 0


add_vec = lambda u, v: [vi + ui for vi, ui in zip(v, u)]
sub_vec = lambda u, v: [vi - ui for vi, ui in zip(v, u)]


# add_vec = lambda u, v: tuple(ui + vi for ui, vi in zip(u, v))
def add_vec2(u: list[int], v: list[int]):
    for i in range(2):
        u[i] += v[i]


# sorted(((x, sum(map(abs, x[1]))) for x in ishall), key=lambda i: i[1])
# isrink = tuple(
#     Line(a[:2], b[:2]) for (a, b), _ in sorted(((x, sum(map(abs, x[1]))) for x in ishall), key=lambda i: i[1])
# )


add_vec = lambda u, v: [vi + ui for vi, ui in zip(v, u)]
sub_vec = lambda u, v: [vi - ui for vi, ui in zip(v, u)]


def determinant3(mat: list[Vec3] | tuple[Vec3, ...] | tuple[Vec3, Vec3, Vec3]) -> int:
    (a, b, c), (d, e, f), (g, h, i) = mat  # Rule of Sarrus. Paranthesis below for readability
    return (a * e * i) + (b * f * g) + (c * d * h) - (c * e * g) - (b * d * i) - (a * f * h)


def cross_vec3(a: Vec3, b: Vec3) -> Vec3:
    (a1, a2, a3), (b1, b2, b3) = a, b
    return a2 * b3 - a3 * b2, a3 * b1 - a1 * b3, a1 * b2 - a2 * b1


def crosses(a: tuple[Vec3, Vec3], b: tuple[Vec3, Vec3]) -> None | tuple[float, float]:
    ((pa1, pa2, _), (da1, da2, _)), ((pb1, pb2, _), (db1, db2, _)) = a, b
    if det := da2 * db1 - da1 * db2:  # Linear dependent vectors equals zero.
        dx, dy = pb1 - pa1, pb2 - pa2
        if (u := (dy * db1 - dx * db2) / det) >= 0 and (dy * da1 - dx * da2) / det >= 0:
            return (pa1 + da1 * u, pa2 + da2 * u)


isrink = sorted(((x, sum(map(abs, x[1]))) for x in ishall), key=lambda i: i[0])

mat3: list[tuple[Vec3, Vec3]] = []
for posdir in ishall:  # Find 3 independent vectors, super naive
    if len(mat3) == 3:
        if determinant3(list(zip(*mat3))[1]) != 0:
            break
        mat3.clear()
    mat3.append(posdir)
# Mp, Md = list(zip(*mat3))
mat3 = [ishall[0], ishall[1], ishall[3]]

pa, da = mat3[0]
pb, db = mat3[1]
pc, dc = mat3[2]
