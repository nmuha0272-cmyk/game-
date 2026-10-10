"""Turns a huge AI-made model (.glb from Tripo: millions of triangles, 4K
textures, no skeleton) into a game-ready one:
  1. fewer triangles (about 30,000), smaller textures (1024),
  2. a Mixamo-style skeleton (bones named mixamorig_Hips, ...) placed from
     the shape of the body (it must stand in a T-pose or A-pose, facing +Z),
  3. every vertex attached to its nearest bones, so the body can bend.
    python3 tools/make_rigged_character.py input.glb output.glb [triangles] [--no-rig] [--joints=file.json] [--tex=512]
Keep the model exactly as it is (only add the skeleton): triangles 0 and --tex=0.
A model that isn't in a T-pose (like the hunched monster) gets its joints
from a .json file instead (see tools/rigs/long_man.json).
"""
import io, json, struct, sys
import numpy as np
import fast_simplification
from PIL import Image

sys.path.insert(0, __import__("os").path.dirname(__import__("os").path.abspath(__file__)))
from fix_glb_skeleton import read_accessor

TEXTURE_SIZE = 1024


def load(path):
    b = open(path, "rb").read()
    clen = struct.unpack("<I", b[12:16])[0]
    j = json.loads(b[20:20 + clen])
    blen = struct.unpack("<I", b[20 + clen:24 + clen])[0]
    return j, bytes(b[28 + clen:28 + clen + blen])


def simplify(P, N, UV, F, target):
    """Fewer triangles. The mesh is split where texture pieces meet, so it is
    first welded into one surface (no cracks), simplified, and then each kept
    triangle takes the texture coordinates of the original triangle it came
    from (so texture pieces don't bleed into each other)."""
    if len(F) <= target:
        return P, N, UV, F
    uniq, weld = np.unique(np.round(P, 6), axis=0, return_inverse=True)
    weld = weld.reshape(-1)
    WF = weld[F]
    _, _, collapses = fast_simplification.simplify(uniq, WF, target_reduction=1.0 - target / len(F), agg=5, return_collapses=True)
    P2, F2, mapping = fast_simplification.replay_simplification(uniq, WF, collapses)
    # Every original triangle that is still a triangle after the collapses.
    M = mapping[WF]
    keep = (M[:, 0] != M[:, 1]) & (M[:, 1] != M[:, 2]) & (M[:, 0] != M[:, 2])
    # Smooth normals on the welded surface.
    N2 = np.zeros_like(P2)
    fn = np.cross(P2[F2[:, 1]] - P2[F2[:, 0]], P2[F2[:, 2]] - P2[F2[:, 0]])
    for k in range(3):
        np.add.at(N2, F2[:, k], fn)
    N2 /= np.maximum(np.linalg.norm(N2, axis=1, keepdims=True), 1e-12)
    # Each triangle belongs to one texture piece ("island") of the original.
    from scipy.sparse import coo_matrix
    from scipy.sparse.csgraph import connected_components
    from scipy.spatial import cKDTree
    e = np.concatenate([F[:, [0, 1]], F[:, [1, 2]]])
    _, comp = connected_components(coo_matrix((np.ones(len(e)), (e[:, 0], e[:, 1])), shape=(len(P), len(P))), directed=False)
    tri_island = comp[F[:, 0]]
    orig_of = {}
    for tri, oi in zip(M[keep], np.nonzero(keep)[0]):
        orig_of.setdefault(tuple(sorted(tri)), oi)
    new_island = np.array([tri_island[orig_of[tuple(sorted(t))]] if tuple(sorted(t)) in orig_of else -1 for t in F2])
    # For every corner: the closest point on the original surface (same
    # island), and the texture coordinate there.
    corners = []  # (new vertex, island)
    verts, out_f = {}, []
    for t, isl in zip(F2, new_island):
        face = []
        for v in t:
            key = (int(v), int(isl))
            if key not in verts:
                verts[key] = len(verts)
                corners.append(key)
            face.append(verts[key])
        out_f.append(face)
    cv = np.array([c[0] for c in corners]); ci = np.array([c[1] for c in corners])
    UV3 = np.zeros((len(corners), 2), dtype=np.float32)
    A, B, C = P[F[:, 0]], P[F[:, 1]], P[F[:, 2]]
    for isl in np.unique(ci):
        sel = np.nonzero(ci == isl)[0]
        tris = np.nonzero(tri_island == isl)[0] if isl >= 0 else np.arange(len(F))
        tree = cKDTree((A[tris] + B[tris] + C[tris]) / 3)
        k = min(8, len(tris))
        _, nn = tree.query(P2[cv[sel]], k=k)
        nn = tris[nn.reshape(len(sel), k)]
        q = P2[cv[sel]][:, None, :]
        uvw, dist = closest_on_triangles(q, A[nn], B[nn], C[nn])
        best = np.argmin(dist, axis=1)
        r = np.arange(len(sel))
        bt, bw = nn[r, best], uvw[r, best]
        UV3[sel] = bw[:, 0:1] * UV[F[bt, 0]] + bw[:, 1:2] * UV[F[bt, 1]] + bw[:, 2:3] * UV[F[bt, 2]]
    return P2[cv].astype(np.float32), N2[cv].astype(np.float32), UV3, np.array(out_f, dtype=np.uint32)


def closest_on_triangles(p, a, b, c):
    """Barycentric weights of the closest point on each triangle to p, and the distance."""
    ab, ac, ap = b - a, c - a, p - a
    d00 = (ab * ab).sum(-1); d01 = (ab * ac).sum(-1); d11 = (ac * ac).sum(-1)
    d20 = (ap * ab).sum(-1); d21 = (ap * ac).sum(-1)
    den = np.maximum(d00 * d11 - d01 * d01, 1e-20)
    v = (d11 * d20 - d01 * d21) / den
    w = (d00 * d21 - d01 * d20) / den
    # Clamp into the triangle (good enough for picking a texture spot).
    v = np.clip(v, 0, 1); w = np.clip(w, 0, 1)
    over = v + w > 1
    sv = v + w
    v = np.where(over, v / np.maximum(sv, 1e-12), v); w = np.where(over, w / np.maximum(sv, 1e-12), w)
    u = 1 - v - w
    pt = u[..., None] * a + v[..., None] * b + w[..., None] * c
    return np.stack([u, v, w], -1), np.linalg.norm(p - pt, axis=-1)


def shrink_image(data, mime):
    if TEXTURE_SIZE <= 0:
        return data  # --tex=0: keep the original texture exactly as it is
    im = Image.open(io.BytesIO(data))
    im.thumbnail((TEXTURE_SIZE, TEXTURE_SIZE), Image.LANCZOS)
    out = io.BytesIO()
    if mime == "image/png":
        im.save(out, "PNG", optimize=True)
    else:
        im.convert("RGB").save(out, "JPEG", quality=88)
    return out.getvalue()


# --- The skeleton -------------------------------------------------------
# name, parent. Positions come from measure().
BONES = [("Hips", None), ("Spine", "Hips"), ("Spine1", "Spine"), ("Spine2", "Spine1"), ("Neck", "Spine2"), ("Head", "Neck"),
         ("HeadTop_End", "Head"),
         ("LeftShoulder", "Spine2"), ("LeftArm", "LeftShoulder"), ("LeftForeArm", "LeftArm"), ("LeftHand", "LeftForeArm"), ("LeftHandEnd", "LeftHand"),
         ("RightShoulder", "Spine2"), ("RightArm", "RightShoulder"), ("RightForeArm", "RightArm"), ("RightHand", "RightForeArm"), ("RightHandEnd", "RightHand"),
         ("LeftUpLeg", "Hips"), ("LeftLeg", "LeftUpLeg"), ("LeftFoot", "LeftLeg"), ("LeftToeBase", "LeftFoot"), ("LeftToe_End", "LeftToeBase"),
         ("RightUpLeg", "Hips"), ("RightLeg", "RightUpLeg"), ("RightFoot", "RightLeg"), ("RightToeBase", "RightFoot"), ("RightToe_End", "RightToeBase")]
ENDS = {"HeadTop_End", "LeftHandEnd", "RightHandEnd", "LeftToe_End", "RightToe_End"}


def measure(P):
    """Finds the joints from the body's shape. Mixamo's left is the
    character's left, which is -X when it faces +Z... no: facing +Z, the
    character's left hand is at +X."""
    h = P[:, 1].max()
    xmax = np.abs(P[:, 0]).max()
    # Arm height: where the body is widest (the arms stick out).
    far = P[np.abs(P[:, 0]) > 0.7 * xmax]
    arm_y = float(np.median(far[:, 1]))
    # Torso half-width just under the armpits.
    band = P[(P[:, 1] > arm_y - 0.12 * h) & (P[:, 1] < arm_y - 0.07 * h)]
    xs = np.sort(np.abs(band[:, 0]))
    torso = float(xs[int(len(xs) * 0.6)]) if len(xs) else 0.12 * h
    torso = min(torso, 0.16 * h)
    # Legs: the gap between them near the knees.
    knee_y = 0.28 * h
    legs = P[np.abs(P[:, 1] - knee_y) < 0.03 * h]
    leg_x = float(np.median(np.abs(legs[:, 0]))) if len(legs) else 0.09 * h
    zc = float(np.median(P[(P[:, 1] > 0.4 * h) & (P[:, 1] < 0.7 * h)][:, 2]))
    hip_y = 0.52 * h
    J = {
        "Hips": (0, hip_y, zc), "Spine": (0, 0.58 * h, zc), "Spine1": (0, 0.65 * h, zc), "Spine2": (0, 0.72 * h, zc),
        "Neck": (0, 0.83 * h, zc), "Head": (0, 0.875 * h, zc), "HeadTop_End": (0, h, zc),
    }
    wrist_x = 0.82 * xmax
    for side, s in (("Left", 1), ("Right", -1)):
        sh_x = torso * 0.95
        J[side + "Shoulder"] = (s * 0.035 * h, arm_y - 0.01 * h, zc)
        J[side + "Arm"] = (s * sh_x, arm_y, zc)
        J[side + "ForeArm"] = (s * (sh_x + wrist_x) / 2, arm_y, zc)
        J[side + "Hand"] = (s * wrist_x, arm_y, zc)
        J[side + "HandEnd"] = (s * xmax, arm_y, zc)
        J[side + "UpLeg"] = (s * leg_x, hip_y - 0.03 * h, zc)
        J[side + "Leg"] = (s * leg_x, knee_y, zc)
        J[side + "Foot"] = (s * leg_x, 0.06 * h, zc - 0.01 * h)
        J[side + "ToeBase"] = (s * leg_x, 0.015 * h, zc + 0.08 * h)
        J[side + "Toe_End"] = (s * leg_x, 0.015 * h, zc + 0.13 * h)
    return {k: np.array(v, dtype=float) for k, v in J.items()}


def seg_dist(P, a, b):
    ab = b - a
    t = np.clip(((P - a) @ ab) / max(ab @ ab, 1e-12), 0, 1)
    return np.linalg.norm(P - (a + t[:, None] * ab), axis=1)


def skin_weights(P, J, names):
    """Each vertex: up to 4 nearest bone segments, weight 1/d^4."""
    child = {}
    for n, p in BONES:
        if p and p not in child:
            child[p] = n
    skinned = [n for n in names if n not in ENDS]
    D = np.stack([seg_dist(P, J[n], J[child[n]]) for n in skinned], axis=1)
    # Arms are only arms beyond the armpit; legs only below the hips (stops
    # the hand bones grabbing the hips when the arms hang down, etc.).
    for k, n in enumerate(skinned):
        if "Arm" in n or "Hand" in n:
            sx = abs(J[n.replace("ForeArm", "Arm").replace("Hand", "Arm")][0])
            D[np.abs(P[:, 0]) < sx * 0.85, k] += 10.0
        if "Leg" in n or "Foot" in n or "Toe" in n:
            D[P[:, 1] > J["Hips"][1], k] += 10.0
            side = 1 if n.startswith("Left") else -1
            D[P[:, 0] * side < -0.01, k] += 10.0
    top = np.argsort(D, axis=1)[:, :4]
    d = np.take_along_axis(D, top, axis=1)
    near = d[:, :1]
    w = 1.0 / np.maximum(d, 1e-4) ** 4
    w[d > near * 1.6 + 0.01] = 0
    w /= w.sum(axis=1, keepdims=True)
    joint_index = {n: i for i, n in enumerate(names)}
    J4 = np.vectorize(lambda k: joint_index[skinned[k]])(top).astype(np.uint16)
    return J4, w.astype(np.float32)


def joints_from_file(path):
    data = json.load(open(path))
    J = {k: np.array(v, dtype=float) for k, v in data.items() if not k.startswith("_")}
    for k in list(J):
        if k.startswith("Left"):
            J["Right" + k[4:]] = J[k] * np.array([-1, 1, 1])
    return J


def main(src, dst, target=30000, rig=True, joints=None):
    j, binary = load(src)
    prim = j["meshes"][0]["primitives"][0]
    P = read_accessor(j, binary, prim["attributes"]["POSITION"]).astype(np.float64)
    N = read_accessor(j, binary, prim["attributes"]["NORMAL"]).astype(np.float32)
    UV = read_accessor(j, binary, prim["attributes"]["TEXCOORD_0"]).astype(np.float32)
    F = read_accessor(j, binary, prim["indices"]).reshape(-1, 3).astype(np.int64)
    # Bake the node's own transform (if any) into the vertices.
    P, N, UV, F = simplify(P, N, UV, F, target)
    out = bytearray()
    views, accs = [], []

    def add(data, comp, count, typ, target_=None, minmax=False):
        while len(out) % 4:
            out.append(0)
        view = {"buffer": 0, "byteOffset": len(out), "byteLength": len(data)}
        if target_:
            view["target"] = target_
        views.append(view)
        out.extend(data)
        a = {"bufferView": len(views) - 1, "componentType": comp, "count": count, "type": typ}
        accs.append(a)
        return len(accs) - 1, a

    pa, a = add(P.astype(np.float32).tobytes(), 5126, len(P), "VEC3", 34962)
    a["min"] = P.min(axis=0).tolist(); a["max"] = P.max(axis=0).tolist()
    na, _ = add(N.tobytes(), 5126, len(N), "VEC3", 34962)
    ua, _ = add(UV.tobytes(), 5126, len(UV), "VEC2", 34962)
    ia, _ = add(F.astype(np.uint32).tobytes(), 5125, F.size, "SCALAR", 34963)
    attrs = {"POSITION": pa, "NORMAL": na, "TEXCOORD_0": ua}
    nodes = [{"name": "Mesh", "mesh": 0}]
    root_children = [0]
    skins = []
    if rig:
        J = joints_from_file(joints) if joints else measure(P)
        names = [n for n, _ in BONES]
        for i, (n, parent) in enumerate(BONES):
            pos = J[n] - (J[parent] if parent else 0)
            nodes.append({"name": "mixamorig_" + n, "translation": pos.tolist()})
        for i, (n, parent) in enumerate(BONES):
            if parent:
                nodes[1 + names.index(parent)].setdefault("children", []).append(1 + i)
        J4, W4 = skin_weights(P, J, names)
        attrs["JOINTS_0"], _ = add(J4.tobytes(), 5123, len(J4), "VEC4", 34962)
        attrs["WEIGHTS_0"], _ = add(W4.tobytes(), 5126, len(W4), "VEC4", 34962)
        ibm = np.zeros((len(names), 4, 4), dtype=np.float32)
        for i, n in enumerate(names):
            m = np.eye(4); m[:3, 3] = -J[n]
            ibm[i] = m.T  # column-major
        ib, _ = add(ibm.tobytes(), 5126, len(names), "MAT4")
        skins = [{"joints": list(range(1, 1 + len(names))), "inverseBindMatrices": ib, "skeleton": 1}]
        nodes[0]["skin"] = 0
        root_children.append(1)
    images = []
    for im in j.get("images", []):
        v = j["bufferViews"][im["bufferView"]]
        data = binary[v.get("byteOffset", 0):v.get("byteOffset", 0) + v["byteLength"]]
        small = shrink_image(data, im.get("mimeType", "image/jpeg"))
        while len(out) % 4:
            out.append(0)
        views.append({"buffer": 0, "byteOffset": len(out), "byteLength": len(small)})
        out.extend(small)
        images.append({"bufferView": len(views) - 1, "mimeType": im.get("mimeType", "image/jpeg")})
    while len(out) % 4:
        out.append(0)
    mat = prim.get("material", 0)
    g = {"asset": {"version": "2.0", "generator": "make_rigged_character.py"}, "scene": 0,
         "scenes": [{"nodes": [len(nodes)]}],
         "nodes": nodes + [{"name": "Root", "children": root_children}],
         "meshes": [{"name": "Body", "primitives": [{"attributes": attrs, "indices": ia, "material": 0}]}],
         "materials": [j["materials"][mat]] if "materials" in j else [],
         "textures": j.get("textures", []), "samplers": j.get("samplers", []), "images": images,
         "accessors": accs, "bufferViews": views, "buffers": [{"byteLength": len(out)}]}
    if skins:
        g["skins"] = skins
    js = json.dumps(g, separators=(",", ":")).encode()
    js += b" " * (-len(js) % 4)
    with open(dst, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(out)))
        f.write(struct.pack("<II", len(js), 0x4E4F534A)); f.write(js)
        f.write(struct.pack("<II", len(out), 0x004E4942)); f.write(out)
    print(f"{dst}: {len(F)} triangles, {len(P)} vertices" + (f", {len(BONES)} bones" if rig else ""))


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    jf = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--joints=")), None)
    tex = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--tex=")), None)
    if tex:
        TEXTURE_SIZE = int(tex)
    target = int(args[2]) if len(args) > 2 else 30000
    main(args[0], args[1], target if target > 0 else 10 ** 12, "--no-rig" not in sys.argv, jf)
