"""Rebuilds the Long Man's body (the "Body" node in scenes/monsters/long_man.tscn)
out of simple shapes: starved and hunched, long jointed arms with spindly
fingers, a torn hospital gown, a tilted head with an open jaw.
Run: python3 tools/make_long_man_body.py"""
import os, random, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from tscn import xform

PATH = "scenes/monsters/long_man.tscn"
s = open(PATH).read()

# 1. Drop the old body parts (every node whose parent is Body).
s = re.sub(r'\[node name="[^"]+" type="\w+" parent="Body[^"]*"\]\n(?:[^\[\n].*\n|\n)*?(?=\[node)', "", s)
# 2. Drop old part meshes/material we replace (keep Mat_eye and Mesh_eye).
for sid in ["Mat_skin", "Mat_gown", "Mat_hole", "Mesh_torso", "Mesh_leg", "Mesh_arm", "Mesh_head", r"LM_\w+"]:
    s = re.sub(r'\[sub_resource type="\w+" id="%s"\]\n(?:[^\[\n].*\n)*\n?' % sid, "", s)
s = re.sub(r'\[ext_resource [^\n]*id="lm_\w+"\]\n', "", s)
EXT = ('[ext_resource type="Texture2D" path="res://assets/textures/rock_normal.jpg" id="lm_skin_n"]\n'
       '[ext_resource type="Texture2D" path="res://assets/textures/concrete_wall_albedo.jpg" id="lm_cloth"]\n')
last = s.rindex("[ext_resource")
last = s.index("\n", last) + 1
s = s[:last] + EXT + s[last:]

subs = '''[sub_resource type="StandardMaterial3D" id="Mat_skin"]
albedo_color = Color(0.5, 0.45, 0.42, 1)
albedo_texture = ExtResource("lm_cloth")
roughness = 0.7
normal_enabled = true
normal_scale = 0.6
normal_texture = ExtResource("lm_skin_n")
rim_enabled = true
rim = 0.25
rim_tint = 0.1
uv1_scale = Vector3(3, 3, 3)
uv1_triplanar = true

[sub_resource type="StandardMaterial3D" id="Mat_gown"]
albedo_color = Color(0.55, 0.62, 0.55, 1)
albedo_texture = ExtResource("lm_cloth")
roughness = 0.95
cull_mode = 2
uv1_scale = Vector3(2, 2, 2)
uv1_triplanar = true

[sub_resource type="StandardMaterial3D" id="Mat_hole"]
albedo_color = Color(0.02, 0.0, 0.0, 1)
roughness = 1.0

[sub_resource type="CapsuleMesh" id="LM_thigh"]
radius = 0.07
height = 0.78

[sub_resource type="CapsuleMesh" id="LM_shin"]
radius = 0.055
height = 0.72

[sub_resource type="BoxMesh" id="LM_foot"]
size = Vector3(0.1, 0.05, 0.3)

[sub_resource type="CylinderMesh" id="LM_gown"]
top_radius = 0.2
bottom_radius = 0.31
height = 1.0
radial_segments = 12
rings = 1

[sub_resource type="BoxMesh" id="LM_strip"]
size = Vector3(0.07, 0.4, 0.01)

[sub_resource type="CapsuleMesh" id="LM_chest"]
radius = 0.16
height = 0.8

[sub_resource type="CapsuleMesh" id="LM_rib"]
radius = 0.016
height = 0.3

[sub_resource type="CylinderMesh" id="LM_neck"]
top_radius = 0.045
bottom_radius = 0.06
height = 0.42
radial_segments = 8
rings = 1

[sub_resource type="SphereMesh" id="LM_skull"]
radius = 0.17
height = 0.34

[sub_resource type="SphereMesh" id="LM_hole"]
radius = 0.045
height = 0.09

[sub_resource type="CapsuleMesh" id="LM_upper_arm"]
radius = 0.05
height = 0.88

[sub_resource type="CapsuleMesh" id="LM_forearm"]
radius = 0.04
height = 0.92

[sub_resource type="BoxMesh" id="LM_palm"]
size = Vector3(0.08, 0.15, 0.04)

[sub_resource type="CylinderMesh" id="LM_finger"]
top_radius = 0.004
bottom_radius = 0.009
height = 0.34
radial_segments = 5
rings = 1

'''
s = s.replace('[sub_resource type="SphereMesh" id="Mesh_eye"]', subs + '[sub_resource type="SphereMesh" id="Mesh_eye"]', 1)

nodes = []
def part(name, mesh, mat, pos, yaw=0, pitch=0, roll=0, parent="Body", scale=None):
    t = xform(pos, yaw, pitch, roll)
    if scale:  # scale the basis columns
        vals = [float(v) for v in t[len("Transform3D("):-1].split(",")]
        for r in range(3):
            for c in range(3):
                vals[r * 3 + c] *= scale[c]
        t = "Transform3D(" + ", ".join(f"{v:g}" for v in vals) + ")"
    nodes.append(f'[node name="{name}" type="MeshInstance3D" parent="{parent}"]\ntransform = {t}\n'
                 f'mesh = SubResource("{mesh}")\nsurface_material_override/0 = SubResource("{mat}")\n')

for side, x in (("L", -1), ("R", 1)):
    part(f"Thigh{side}", "LM_thigh", "Mat_skin", (0.12 * x, 0.97, -0.03), pitch=8)
    part(f"Shin{side}", "LM_shin", "Mat_skin", (0.13 * x, 0.33, 0.0), pitch=-6)
    part(f"Foot{side}", "LM_foot", "Mat_skin", (0.13 * x, 0.03, -0.09))
    # Arms hang almost to the ground: shoulder 2.5 -> elbow 1.68 -> wrist 0.8.
    part(f"UpperArm{side}", "LM_upper_arm", "Mat_skin", (0.3 * x, 2.09, -0.19), roll=4 * x, pitch=5)
    part(f"Forearm{side}", "LM_forearm", "Mat_skin", (0.35 * x, 1.24, -0.27), roll=2 * x, pitch=8)
    part(f"Palm{side}", "LM_palm", "Mat_skin", (0.37 * x, 0.72, -0.31))
    for f in range(4):
        part(f"Finger{side}{f}", "LM_finger", "Mat_skin", (0.37 * x + (f - 1.5) * 0.022, 0.48 - abs(f - 1.5) * 0.03, -0.31), pitch=-12, roll=(f - 1.5) * 4)

part("Gown", "LM_gown", "Mat_gown", (0, 1.55, -0.03), pitch=-4)
random.seed(4)
for k in range(8):
    import math
    a = k / 8 * math.tau
    part(f"GownStrip{k}", "LM_strip", "Mat_gown", (math.sin(a) * 0.29, 0.92 - random.random() * 0.12, math.cos(a) * 0.29 - 0.03),
         yaw=math.degrees(a), roll=random.uniform(-14, 14))
part("Chest", "LM_chest", "Mat_skin", (0, 2.25, -0.1), pitch=-18)
for k in range(4):
    part(f"Rib{k}", "LM_rib", "Mat_skin", (0, 2.12 + k * 0.075, -0.235 - k * 0.02), roll=90, yaw=0)
part("Neck", "LM_neck", "Mat_skin", (0, 2.72, -0.3), pitch=-38)

head = ('[node name="HeadPivot" type="Node3D" parent="Body"]\n'
        f'transform = {xform((0, 2.9, -0.42), 0, 0, 14)}\n')
nodes.append(head)
part("Skull", "LM_skull", "Mat_skin", (0, 0.08, 0), parent="Body/HeadPivot", scale=(0.85, 1.4, 1.0))
part("Jaw", "LM_hole", "Mat_hole", (0, -0.07, -0.14), parent="Body/HeadPivot", scale=(0.6, 1.5, 0.45))
for side, x in (("Left", -1), ("Right", 1)):
    part(f"Socket{side}", "LM_hole", "Mat_hole", (0.055 * x, 0.11, -0.135), parent="Body/HeadPivot", scale=(0.9, 0.7, 0.5), roll=-20 * x)
    part(f"Eye{side}", "Mesh_eye", "Mat_eye", (0.055 * x, 0.11, -0.158), parent="Body/HeadPivot", scale=(0.35, 0.35, 0.35))

body_hdr = '[node name="Body" type="Node3D" parent="."]\n'
i = s.index(body_hdr) + len(body_hdr)
# Skip any properties of Body itself.
j = s.index("\n[node", i - 1) + 1
s = s[:j] + "\n".join(nodes) + "\n" + s[j:]
s = re.sub(r"load_steps=\d+", "load_steps=%d" % (s.count("[ext_resource") + s.count("[sub_resource") + 1), s, 1)
open(PATH, "w").write(s)
print("Long Man body rebuilt:", len(nodes), "parts")
