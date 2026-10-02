"""Puts the sculpted Long Man (tools/make_long_man.py) into
scenes/monsters/long_man.tscn: the body, the twitching head and its eyes.
Run: python3 tools/make_long_man_body.py"""
import os, random, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from tscn import xform

PATH = "scenes/monsters/long_man.tscn"
s = open(PATH).read()

# 1. Drop the old body parts (every node whose parent is Body).
s = re.sub(r'\[node name="[^"]+" type="\w+" parent="(?:Crawl)?Body[^"]*"\]\n(?:[^\[\n].*\n|\n)*?(?=\[node)', "", s)
s = re.sub(r'\[node name="CrawlBody" type="Node3D" parent="\."\]\n(?:[^\[\n].*\n|\n)*?(?=\[node)', "", s)
# 2. Drop old part meshes/material we replace (keep Mat_eye and Mesh_eye).
for sid in ["Mat_skin", "Mat_gown", "Mat_hole", "Mat_bracelet", "Mat_guts", "Mat_flesh", "Mesh_torso", "Mesh_leg", "Mesh_arm", "Mesh_head", r"LM_\w+"]:
    s = re.sub(r'\[sub_resource type="\w+" id="%s"\]\n(?:[^\[\n].*\n)*\n?' % sid, "", s)
s = re.sub(r'\[ext_resource [^\n]*id="lm_\w+"\]\n', "", s)
EXT = ('[ext_resource type="Texture2D" path="res://assets/textures/rock_normal.jpg" id="lm_skin_n"]\n'
       '[ext_resource type="Texture2D" path="res://assets/textures/concrete_wall_albedo.jpg" id="lm_cloth"]\n'
       '[ext_resource type="ArrayMesh" path="res://assets/models/long_man_body.obj" id="lm_body_mesh"]\n'
       '[ext_resource type="ArrayMesh" path="res://assets/models/long_man_head.obj" id="lm_head_mesh"]\n'
       + "".join(f'[ext_resource type="ArrayMesh" path="res://assets/models/long_man_crawl_{p}.obj" id="lm_crawl_{p}"]\n'
                 for p in ("body", "arm_l", "arm_r", "leg_l", "leg_r")))
last = s.rindex("[ext_resource")
last = s.index("\n", last) + 1
s = s[:last] + EXT + s[last:]

subs = '''[sub_resource type="StandardMaterial3D" id="Mat_skin"]
albedo_color = Color(0.62, 0.57, 0.52, 1)
albedo_texture = ExtResource("lm_cloth")
roughness = 0.6
normal_enabled = true
normal_scale = 0.5
normal_texture = ExtResource("lm_skin_n")
rim_enabled = true
rim = 0.3
rim_tint = 0.1
uv1_scale = Vector3(3, 3, 3)
uv1_triplanar = true

[sub_resource type="StandardMaterial3D" id="Mat_gown"]
albedo_color = Color(0.62, 0.68, 0.6, 1)
albedo_texture = ExtResource("lm_cloth")
roughness = 0.95
cull_mode = 2
uv1_scale = Vector3(2, 2, 2)
uv1_triplanar = true

[sub_resource type="StandardMaterial3D" id="Mat_bracelet"]
albedo_color = Color(0.5, 0.5, 0.47, 1)
metallic = 0.8
roughness = 0.45

[sub_resource type="StandardMaterial3D" id="Mat_guts"]
albedo_color = Color(0.26, 0.07, 0.06, 1)
roughness = 0.35
metallic_specular = 0.7
rim_enabled = true
rim = 0.2

[sub_resource type="StandardMaterial3D" id="Mat_flesh"]
albedo_color = Color(0.1, 0.015, 0.015, 1)
roughness = 0.3

[sub_resource type="StandardMaterial3D" id="Mat_hole"]
albedo_color = Color(0.02, 0.0, 0.0, 1)
roughness = 1.0

'''
s = s.replace('[sub_resource type="SphereMesh" id="Mesh_eye"]', subs + '[sub_resource type="SphereMesh" id="Mesh_eye"]', 1)


def mesh_node(name, mesh_id, materials, pos=(0, 0, 0), parent="Body", roll=0):
    lines = [f'[node name="{name}" type="MeshInstance3D" parent="{parent}"]', f"transform = {xform(pos, 0, 0, roll)}",
             f'mesh = ExtResource("{mesh_id}")']
    lines += [f'surface_material_override/{i} = SubResource("{m}")' for i, m in enumerate(materials)]
    return "\n".join(lines) + "\n"


nodes = [mesh_node("Sculpt", "lm_body_mesh", ["Mat_skin", "Mat_gown", "Mat_bracelet", "Mat_guts", "Mat_flesh", "Mat_flesh"]),
         '[node name="HeadPivot" type="Node3D" parent="Body"]\n' + f"transform = {xform((0, 2.567, -0.386), 0, 0, 14)}\n",
         mesh_node("Head", "lm_head_mesh", ["Mat_skin", "Mat_hole"], parent="Body/HeadPivot")]
for side, x in (("Left", -1), ("Right", 1)):
    nodes.append(f'[node name="Eye{side}" type="MeshInstance3D" parent="Body/HeadPivot"]\n'
                 f"transform = Transform3D(0.22, 0, 0, 0, 0.16, 0, 0, 0, 0.22, {0.046 * x:g}, 0.101, -0.106)\n"
                 'mesh = SubResource("Mesh_eye")\nsurface_material_override/0 = SubResource("Mat_eye")\n')

# The crawling body (shown while he hunts; monster_visuals.gd switches between them).
import json
rig = json.load(open("assets/models/long_man_crawl_rig.json"))
crawl = ['[node name="CrawlBody" type="Node3D" parent="."]\nvisible = false\n',
         mesh_node("Sculpt", "lm_crawl_body", ["Mat_skin", "Mat_gown", "Mat_guts"], parent="CrawlBody")]
for limb, key in (("ArmL", "shoulder_l"), ("ArmR", "shoulder_r"), ("LegL", "hip_l"), ("LegR", "hip_r")):
    crawl.append(f'[node name="{limb}" type="Node3D" parent="CrawlBody"]\ntransform = {xform(tuple(rig[key]))}\n')
    crawl.append(mesh_node("Mesh", "lm_crawl_" + key.replace("shoulder", "arm").replace("hip", "leg"), ["Mat_skin"], parent="CrawlBody/" + limb))
crawl.append('[node name="HeadPivot" type="Node3D" parent="CrawlBody"]\n' + f"transform = {xform(tuple(rig['head']), 0, 25, 10)}\n")
crawl.append(mesh_node("Head", "lm_head_mesh", ["Mat_skin", "Mat_hole"], parent="CrawlBody/HeadPivot"))
for side, x in (("Left", -1), ("Right", 1)):
    crawl.append(f'[node name="Eye{side}" type="MeshInstance3D" parent="CrawlBody/HeadPivot"]\n'
                 f"transform = Transform3D(0.22, 0, 0, 0, 0.16, 0, 0, 0, 0.22, {0.046 * x:g}, 0.101, -0.106)\n"
                 'mesh = SubResource("Mesh_eye")\nsurface_material_override/0 = SubResource("Mat_eye")\n')
nodes += crawl

body_hdr = '[node name="Body" type="Node3D" parent="."]\n'
i = s.index(body_hdr) + len(body_hdr)
# Skip any properties of Body itself.
j = s.index("\n[node", i - 1) + 1
s = s[:j] + "\n".join(nodes) + "\n" + s[j:]
s = re.sub(r"load_steps=\d+", "load_steps=%d" % (s.count("[ext_resource") + s.count("[sub_resource") + 1), s, 1)
open(PATH, "w").write(s)
print("Long Man body rebuilt:", len(nodes), "parts")
