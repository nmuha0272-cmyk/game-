"""Makes a .zip that Mixamo (mixamo.com) accepts: the model as .obj + .mtl
+ its color texture, from one of our game-ready .glb files (T-pose, no rig needed).
    python3 tools/make_mixamo_zip.py assets/models/characters/eli.glb downloads/for_mixamo/eli.zip
"""
import io, json, os, struct, sys, zipfile
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fix_glb_skeleton import read_accessor


def main(src, dst):
    b = open(src, "rb").read()
    clen = struct.unpack("<I", b[12:16])[0]
    j = json.loads(b[20:20 + clen])
    binary = b[28 + clen:]
    prim = j["meshes"][0]["primitives"][0]
    P = read_accessor(j, binary, prim["attributes"]["POSITION"]) * 100.0  # Mixamo likes centimeters
    UV = read_accessor(j, binary, prim["attributes"]["TEXCOORD_0"])
    F = read_accessor(j, binary, prim["indices"]).reshape(-1, 3) + 1
    name = os.path.splitext(os.path.basename(src))[0]
    lines = [f"mtllib {name}.mtl", f"o {name}"]
    lines += [f"v {x:.4f} {y:.4f} {z:.4f}" for x, y, z in P]
    lines += [f"vt {u:.5f} {1 - v:.5f}" for u, v in UV]
    lines += ["usemtl body"] + [f"f {a}/{a} {c}/{c} {d}/{d}" for a, c, d in F]
    tex = j["materials"][0]["pbrMetallicRoughness"]["baseColorTexture"]["index"]
    img = j["images"][j["textures"][tex]["source"]]
    view = j["bufferViews"][img["bufferView"]]
    data = binary[view.get("byteOffset", 0):view.get("byteOffset", 0) + view["byteLength"]]
    ext = "png" if img.get("mimeType") == "image/png" else "jpg"
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr(f"{name}.obj", "\n".join(lines) + "\n")
        z.writestr(f"{name}.mtl", f"newmtl body\nKd 1 1 1\nmap_Kd {name}.{ext}\n")
        z.writestr(f"{name}.{ext}", data)
    print(dst, os.path.getsize(dst) // 1024, "KB")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
