"""Re-rigs an AI-made humanoid .glb (Mixamo bone names) whose skin weights are
broken (e.g. everything stuck to the hips) or whose skeleton is turned
compared with the mesh:
  1. turns the skeleton (around the up axis) so the joints sit inside the body,
  2. gives every vertex new weights from the nearest bones,
  3. writes proper bone positions and inverse bind matrices.
    python3 tools/rerig_glb.py input.glb output.glb
"""
import json, struct, sys
import numpy as np
from scipy.spatial import cKDTree

sys.path.insert(0, __import__("os").path.dirname(__import__("os").path.abspath(__file__)))
from fix_glb_skeleton import read_accessor, mat_to_trs

# Bones that get weights (fingers and toe tips just follow their hand/foot).
MAIN = ["Hips", "Spine", "Spine1", "Spine2", "Neck", "Head",
        "LeftShoulder", "LeftArm", "LeftForeArm", "LeftHand", "RightShoulder", "RightArm", "RightForeArm", "RightHand",
        "LeftUpLeg", "LeftLeg", "LeftFoot", "LeftToeBase", "RightUpLeg", "RightLeg", "RightFoot", "RightToeBase"]
# Where each bone's segment ends (its "child" joint), for the distance test.
END = {"Hips": "Spine", "Spine": "Spine1", "Spine1": "Spine2", "Spine2": "Neck", "Neck": "Head", "Head": "HeadTop_End",
       "LeftShoulder": "LeftArm", "LeftArm": "LeftForeArm", "LeftForeArm": "LeftHand", "LeftHand": "LeftHandMiddle2",
       "RightShoulder": "RightArm", "RightArm": "RightForeArm", "RightForeArm": "RightHand", "RightHand": "RightHandMiddle2",
       "LeftUpLeg": "LeftLeg", "LeftLeg": "LeftFoot", "LeftFoot": "LeftToeBase", "LeftToeBase": "LeftToe_End",
       "RightUpLeg": "RightLeg", "RightLeg": "RightFoot", "RightFoot": "RightToeBase", "RightToeBase": "RightToe_End"}


def seg_dist(P, a, b):
    ab = b - a
    t = np.clip(((P - a) @ ab) / max(ab @ ab, 1e-12), 0, 1)
    return np.linalg.norm(P - (a + t[:, None] * ab), axis=1)


def rot_y(deg):
    a = np.radians(deg)
    return np.array([[np.cos(a), 0, np.sin(a), 0], [0, 1, 0, 0], [-np.sin(a), 0, np.cos(a), 0], [0, 0, 0, 1]])


def main(src, dst):
    b = open(src, "rb").read()
    clen = struct.unpack("<I", b[12:16])[0]
    j = json.loads(b[20:20 + clen])
    blen = struct.unpack("<I", b[20 + clen:24 + clen])[0]
    binary = bytearray(b[28 + clen:28 + clen + blen])
    skin = j["skins"][0]
    acc = j["accessors"][skin["inverseBindMatrices"]]
    bv = j["bufferViews"][acc["bufferView"]]
    ibm = np.frombuffer(bytes(binary), dtype="<f4", count=acc["count"] * 16,
                        offset=bv.get("byteOffset", 0) + acc.get("byteOffset", 0)).reshape(-1, 4, 4).transpose(0, 2, 1)
    joints = skin["joints"]
    name = {ji: j["nodes"][ji]["name"].split(":")[-1].replace("mixamorig_", "") for ji in range(len(j["nodes"]))}
    by_name = {name[ji]: ji for ji in range(len(j["nodes"]))}
    parent = {c: i for i, n in enumerate(j["nodes"]) for c in n.get("children", [])}
    world = {ji: np.linalg.inv(ibm[k].astype(float)) for k, ji in enumerate(joints)}
    # Joints that aren't skinned (ends): place them by their own stored offset, or at the parent.
    for ji in range(len(j["nodes"])):
        if name[ji] in END.values() and ji not in world:
            p = parent.get(ji)
            world[ji] = world.get(p, np.eye(4)).copy()
    prim = j["meshes"][0]["primitives"][0]
    pos = read_accessor(j, bytes(binary), prim["attributes"]["POSITION"])
    tree = cKDTree(pos)
    # 1. Which turn puts the limb joints inside the body?
    test = [by_name[n] for n in MAIN if n in by_name and by_name[n] in world]
    best = None
    for deg in (0, 90, 180, 270):
        pts = np.array([(rot_y(deg) @ world[ji])[:3, 3] for ji in test])
        err = tree.query(pts)[0].mean()
        print(f"  turn {deg:3d}: joints are {err:.3f} from the body")
        if best is None or err < best[1]:
            best = (deg, err)
    turn = rot_y(best[0])
    for ji in world:
        world[ji] = turn @ world[ji]
    # Bones that have no stored end point: extend them along their parent direction.
    for bone, end in END.items():
        e = by_name.get(end)
        if e is not None and np.allclose(world[e][:3, 3], world[by_name[bone]][:3, 3]):
            p = parent.get(by_name[bone])
            d = world[by_name[bone]][:3, 3] - world[p][:3, 3] if p in world else np.array([0, 0.08, 0])
            world[e] = world[by_name[bone]].copy()
            world[e][:3, 3] += d * 0.6
    # 2. New weights: each vertex follows its nearest bones (closest wins most).
    bones = [n for n in MAIN if n in by_name]
    D = np.stack([seg_dist(pos, world[by_name[n]][:3, 3], world[by_name[END[n]]][:3, 3]) for n in bones], axis=1)
    order = np.argsort(D, axis=1)[:, :4]
    d4 = np.take_along_axis(D, order, axis=1)
    w = 1.0 / np.maximum(d4, 0.004) ** 4
    w[d4 > d4[:, :1] * 1.6 + 0.01] = 0          # only bones about as close as the nearest
    w /= w.sum(axis=1, keepdims=True)
    skin_index = {ji: k for k, ji in enumerate(joints)}
    jidx = np.vectorize(lambda i: skin_index[by_name[bones[i]]])(order).astype("<u2")
    # 3. Write it all back: bone transforms, inverse bind matrices, weights.
    for ji in range(len(j["nodes"])):
        if ji not in world:
            continue
        p = parent.get(ji)
        local = np.linalg.inv(world[p]) @ world[ji] if p in world else world[ji]
        t, r, s = mat_to_trs(local)
        node = j["nodes"][ji]
        node.pop("matrix", None)
        node["translation"], node["rotation"], node["scale"] = t, r, [1.0, 1.0, 1.0]
    new_ibm = np.stack([np.linalg.inv(world[ji]) for ji in joints]).astype("<f4").transpose(0, 2, 1)
    start = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
    binary[start:start + new_ibm.nbytes] = new_ibm.tobytes()

    def append(data, comp, count, typ):
        while len(binary) % 4:
            binary.append(0)
        off = len(binary)
        binary.extend(data)
        j["bufferViews"].append({"buffer": 0, "byteOffset": off, "byteLength": len(data)})
        j["accessors"].append({"bufferView": len(j["bufferViews"]) - 1, "componentType": comp, "count": count, "type": typ})
        return len(j["accessors"]) - 1
    prim["attributes"]["JOINTS_0"] = append(jidx.tobytes(), 5123, len(pos), "VEC4")
    prim["attributes"]["WEIGHTS_0"] = append(w.astype("<f4").tobytes(), 5126, len(pos), "VEC4")
    while len(binary) % 4:
        binary.append(0)
    j["buffers"][0]["byteLength"] = len(binary)
    js = json.dumps(j, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    out = struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(js) + 8 + len(binary))
    out += struct.pack("<I4s", len(js), b"JSON") + js + struct.pack("<I4s", len(binary), b"BIN\x00") + bytes(binary)
    open(dst, "wb").write(out)
    counts = np.bincount(order[:, 0], minlength=len(bones))
    print(f"turned the skeleton {best[0]} degrees; vertices per bone:",
          ", ".join(f"{bones[i]} {c}" for i, c in enumerate(counts) if c))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
