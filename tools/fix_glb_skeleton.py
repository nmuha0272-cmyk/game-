"""Fixes AI-made (e.g. Tripo) rigged .glb models whose bones all sit at the
origin. The real bone positions are only stored in the skin's "inverse bind
matrices"; this puts them back into the bones, so bending a bone (an arm, the
head) turns it around the right joint.
    python3 tools/fix_glb_skeleton.py input.glb output.glb
"""
import json, struct, sys
import numpy as np


def mat_to_trs(m):
    t = m[:3, 3].copy()
    s = np.linalg.norm(m[:3, :3], axis=0)
    r = m[:3, :3] / s
    # rotation matrix -> quaternion (x, y, z, w)
    tr = np.trace(r)
    if tr > 0:
        k = 0.5 / np.sqrt(tr + 1.0)
        q = [(r[2, 1] - r[1, 2]) * k, (r[0, 2] - r[2, 0]) * k, (r[1, 0] - r[0, 1]) * k, 0.25 / k]
    else:
        i = int(np.argmax(np.diag(r)))
        j, kk = (i + 1) % 3, (i + 2) % 3
        k = 2.0 * np.sqrt(1.0 + r[i, i] - r[j, j] - r[kk, kk])
        q = [0, 0, 0, 0]
        q[i] = 0.25 * k
        q[j] = (r[j, i] + r[i, j]) / k
        q[kk] = (r[kk, i] + r[i, kk]) / k
        q[3] = (r[kk, j] - r[j, kk]) / k
    q = np.array(q) / np.linalg.norm(q)
    return t.tolist(), q.tolist(), s.tolist()


def read_accessor(j, binary, index):
    acc = j["accessors"][index]
    bv = j["bufferViews"][acc["bufferView"]]
    comps = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[acc["type"]]
    dtype = {5126: "<f4", 5121: "u1", 5123: "<u2", 5125: "<u4"}[acc["componentType"]]
    item = np.dtype(dtype).itemsize * comps
    stride = bv.get("byteStride", item)
    start = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
    raw = np.frombuffer(binary, dtype="u1", count=stride * (acc["count"] - 1) + item, offset=start)
    rows = np.lib.stride_tricks.as_strided(raw, shape=(acc["count"], item), strides=(stride, 1))
    out = np.ascontiguousarray(rows).view(dtype).reshape(acc["count"], comps).astype(float)
    if acc.get("normalized") and dtype != "<f4":
        out /= {"u1": 255.0, "<u2": 65535.0}[dtype]
    return out


def best_turn(j, binary, joints, world):
    prim = j["meshes"][0]["primitives"][0]["attributes"]
    pos = read_accessor(j, binary, prim["POSITION"])
    jnt = read_accessor(j, binary, prim["JOINTS_0"]).astype(int)
    wts = read_accessor(j, binary, prim["WEIGHTS_0"])
    main_joint = jnt[np.arange(len(jnt)), np.argmax(wts, axis=1)]
    targets, points = [], []
    for k, ji in enumerate(joints):
        mine = pos[main_joint == k]
        if len(mine) > 20:
            targets.append(world[ji][:3, 3]); points.append(mine.mean(axis=0))
    targets, points = np.array(targets), np.array(points)
    best, best_err = None, None
    for deg in (0, 90, 180, 270):
        a = np.radians(deg)
        r = np.array([[np.cos(a), 0, np.sin(a), 0], [0, 1, 0, 0], [-np.sin(a), 0, np.cos(a), 0], [0, 0, 0, 1]])
        err = np.mean(np.linalg.norm((targets @ r[:3, :3].T) - points, axis=1))
        print(f"  turn {deg:3d} degrees: joints are {err:.3f} away from their mesh parts")
        if best_err is None or err < best_err:
            best, best_err = (deg, r), err
    return None if best[0] == 0 else best[1]


def main(src, dst):
    b = open(src, "rb").read()
    clen = struct.unpack("<I", b[12:16])[0]
    j = json.loads(b[20:20 + clen])
    bin_start = 20 + clen + 8
    bin_len = struct.unpack("<I", b[20 + clen:24 + clen])[0]
    binary = b[bin_start:bin_start + bin_len]
    skin = j["skins"][0]
    acc = j["accessors"][skin["inverseBindMatrices"]]
    bv = j["bufferViews"][acc["bufferView"]]
    ibm = np.frombuffer(binary, dtype="<f4", count=acc["count"] * 16,
                        offset=bv.get("byteOffset", 0) + acc.get("byteOffset", 0)).reshape(-1, 4, 4).transpose(0, 2, 1)
    joints = skin["joints"]
    parent = {}
    for i, n in enumerate(j["nodes"]):
        for c in n.get("children", []):
            parent[c] = i
    # World matrix of every joint at rest = inverse of its inverse-bind matrix.
    world = {}
    for k, ji in enumerate(joints):
        world[ji] = np.linalg.inv(ibm[k].astype(float))
    # Some exporters store the skeleton turned (e.g. 90 degrees) compared with
    # the mesh. Find the turn (around the up axis) that puts every joint
    # closest to the part of the mesh it moves, and apply it.
    turn = best_turn(j, binary, joints, world)
    if turn is not None:
        for ji in world:
            world[ji] = turn @ world[ji]
        new_ibm = np.stack([np.linalg.inv(world[ji]) for ji in joints]).astype("<f4").transpose(0, 2, 1)
        start = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
        binary = binary[:start] + new_ibm.tobytes() + binary[start + new_ibm.nbytes:]
    # Bones that aren't in the skin (finger/toe ends): put them at their parent.
    def get_world(n):
        if n in world:
            return world[n]
        p = parent.get(n)
        return get_world(p) if p is not None and p in set(joints) | set(world) else np.eye(4)
    changed = 0
    for ji in list(joints) + [n for n in range(len(j["nodes"])) if n not in joints and j["nodes"][n].get("name", "").startswith("mixamorig")]:
        w = get_world(ji)
        p = parent.get(ji)
        pw = get_world(p) if p is not None and (p in world or j["nodes"][p].get("name", "").startswith("mixamorig")) else np.eye(4)
        local = np.linalg.inv(pw) @ w
        t, r, s = mat_to_trs(local)
        node = j["nodes"][ji]
        node.pop("matrix", None)
        node["translation"], node["rotation"], node["scale"] = t, r, s
        changed += 1
    new_json = json.dumps(j, separators=(",", ":")).encode()
    new_json += b" " * ((4 - len(new_json) % 4) % 4)
    out = struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(new_json) + 8 + len(binary))
    out += struct.pack("<I4s", len(new_json), b"JSON") + new_json
    out += struct.pack("<I4s", len(binary), b"BIN\x00") + binary
    open(dst, "wb").write(out)
    print(f"fixed {changed} bones -> {dst}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
