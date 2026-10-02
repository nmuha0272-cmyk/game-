"""A tiny sculpting kit: describe a shape as blended blobs (capsules,
ellipsoids, rounded boxes), and it becomes a smooth 3D model file (.obj).

How it works: every shape is a "distance function" (how far a point is from
its surface). Blending them with a smooth minimum makes them melt together
like clay. Marching cubes then turns that into triangles.
"""
import numpy as np
import fast_simplification
import trimesh
from skimage import measure


# ---------------------------------------------------------------- shapes
# Every shape takes P, an (N, 3) array of points, and returns distances.

def capsule(a, b, r, r2=None):
    a = np.array(a, float); b = np.array(b, float); r2 = r if r2 is None else r2
    def f(P):
        pa = P - a; ba = b - a
        h = np.clip((pa @ ba) / (ba @ ba), 0, 1)
        return np.linalg.norm(pa - h[:, None] * ba, axis=1) - (r + (r2 - r) * h)
    return f


def ellipsoid(c, radii):
    c = np.array(c, float); radii = np.array(radii, float)
    def f(P):
        q = (P - c) / radii
        k0 = np.linalg.norm(q, axis=1)
        k1 = np.linalg.norm(q / radii, axis=1)
        return k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)
    return f


def sphere(c, r):
    return ellipsoid(c, (r, r, r))


def box(c, half, r=0.0):
    c = np.array(c, float); half = np.array(half, float) - r
    def f(P):
        q = np.abs(P - c) - half
        return np.linalg.norm(np.maximum(q, 0), axis=1) + np.minimum(np.max(q, axis=1), 0) - r
    return f


def cone(y_top, r_top, y_bottom, r_bottom, center=(0, 0), z_scale=1.0):
    """A round flared tube (like a long coat or a dress), solid."""
    cx, cz = center
    def f(P):
        y = P[:, 1]
        t = np.clip((y_top - y) / (y_top - y_bottom), 0, 1)
        r = r_top + (r_bottom - r_top) * t
        d = np.sqrt((P[:, 0] - cx) ** 2 + ((P[:, 2] - cz) / z_scale) ** 2) - r
        return np.maximum(d, np.maximum(y - y_top, y_bottom - y))
    return f


def torus_y(c, R, r, z_scale=1.0):
    """A ring around the vertical axis (belts, barrel rims)."""
    c = np.array(c, float)
    def f(P):
        q = P - c
        xz = np.sqrt(q[:, 0] ** 2 + (q[:, 2] / z_scale) ** 2) - R
        return np.sqrt(xz ** 2 + q[:, 1] ** 2) - r
    return f


def cylinder_y(c, r, half_h, round_r=0.01):
    c = np.array(c, float)
    def f(P):
        q = P - c
        d = np.stack([np.sqrt(q[:, 0] ** 2 + q[:, 2] ** 2) - r + round_r, np.abs(q[:, 1]) - half_h + round_r], axis=1)
        return np.minimum(np.max(d, axis=1), 0) + np.linalg.norm(np.maximum(d, 0), axis=1) - round_r
    return f


# ---------------------------------------------------------------- combining

def blend(shapes, k=0.03):
    """Melt shapes together (smooth union). k = how soft the joins are."""
    def f(P):
        d = shapes[0](P)
        for s in shapes[1:]:
            e = s(P)
            h = np.clip(0.5 + 0.5 * (e - d) / k, 0, 1)
            d = e * (1 - h) + d * h - k * h * (1 - h)
        return d
    return f


def union(shapes):
    def f(P):
        return np.min(np.stack([s(P) for s in shapes]), axis=0)
    return f


def cut(shape, cutter, k=0.0):
    """Shape minus cutter."""
    def f(P):
        return np.maximum(shape(P), -cutter(P))
    return f


def bumpy(shape, amount=0.006, freq=40.0, seed=0):
    """Small lumps on the surface (hair, cloth folds, rock)."""
    rng = np.random.default_rng(seed)
    phases = rng.random((3, 3)) * 6.28
    def f(P):
        n = (np.sin(P[:, 0] * freq + phases[0, 0]) * np.sin(P[:, 1] * freq * 1.3 + phases[0, 1])
             + np.sin(P[:, 1] * freq * 0.7 + phases[1, 0]) * np.sin(P[:, 2] * freq + phases[1, 1])
             + np.sin(P[:, 2] * freq * 1.1 + phases[2, 0]) * np.sin(P[:, 0] * freq * 0.9 + phases[2, 1]))
        return shape(P) + n * amount / 3
    return f


def transformed(shape, offset=(0, 0, 0), scale=(1, 1, 1)):
    off = np.array(offset, float); sc = np.array(scale, float)
    def f(P):
        return shape((P - off) / sc) * np.min(sc)
    return f


# ---------------------------------------------------------------- meshing

def mesh(shape, lo, hi, voxel=0.008, faces=8000, smooth=2):
    lo = np.array(lo, float); hi = np.array(hi, float)
    dims = np.ceil((hi - lo) / voxel).astype(int) + 1
    axes = [np.linspace(lo[i], lo[i] + voxel * (dims[i] - 1), dims[i]) for i in range(3)]
    X, Y, Z = np.meshgrid(*axes, indexing="ij")
    P = np.stack([X.ravel(), Y.ravel(), Z.ravel()], axis=1)
    values = np.empty(len(P))
    for start in range(0, len(P), 2_000_000):
        values[start:start + 2_000_000] = shape(P[start:start + 2_000_000])
    values = values.reshape(dims)
    # Close the edges so the mesh never has holes at the box boundary.
    values[0, :, :] = values[-1, :, :] = values[:, 0, :] = values[:, -1, :] = values[:, :, 0] = values[:, :, -1] = 1.0
    if values.min() >= 0:
        return None
    verts, tris, _, _ = measure.marching_cubes(values, 0.0, spacing=(voxel, voxel, voxel))
    verts += lo
    m = trimesh.Trimesh(verts, tris, process=True)
    if smooth:
        trimesh.smoothing.filter_taubin(m, iterations=smooth * 5)
    if len(m.faces) > faces:
        v, f = fast_simplification.simplify(m.vertices, m.faces, 1.0 - faces / len(m.faces))
        m = trimesh.Trimesh(v, f, process=True)
    # Make sure the triangles face outward (a negative volume means inside-out).
    if m.volume < 0:
        m.invert()
    return m


def save_obj(path, parts, pivot=(0, 0, 0)):
    """parts: list of (material_name, color(r,g,b), trimesh). Writes .obj + .mtl.
    Coordinates are moved so `pivot` is the model's origin (where it rotates)."""
    pivot = np.array(pivot, float)
    name = path.rsplit("/", 1)[-1].rsplit(".", 1)[0]
    mtl_lines, obj_lines = [], [f"mtllib {name}.mtl"]
    offset = 1
    for mat_name, color, m in parts:
        if m is None:
            continue
        mtl_lines += [f"newmtl {mat_name}", "Kd %.4f %.4f %.4f" % tuple(color), "Ns 10", "d 1", ""]
        normals = m.vertex_normals
        obj_lines.append(f"o {mat_name}")
        obj_lines.append(f"usemtl {mat_name}")
        for v in m.vertices - pivot:
            obj_lines.append("v %.4f %.4f %.4f" % tuple(v))
        for n in normals:
            obj_lines.append("vn %.4f %.4f %.4f" % tuple(n))
        for f in m.faces + offset:
            obj_lines.append("f %d//%d %d//%d %d//%d" % (f[0], f[0], f[1], f[1], f[2], f[2]))
        offset += len(m.vertices)
    open(path, "w").write("\n".join(obj_lines) + "\n")
    open(path.rsplit(".", 1)[0] + ".mtl", "w").write("\n".join(mtl_lines) + "\n")
