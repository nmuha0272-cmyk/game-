"""Writes the shared materials in assets/materials/ (run after make_textures.py)."""
T = "res://assets/textures/"
OUT = "assets/materials/"


def standard(name, tex, scale, extra="", metal_tex=False, alpha=False, color="1, 1, 1, 1"):
    ext = [("Texture2D", f"{T}{tex}_albedo.{'png' if alpha else 'jpg'}")]
    if not alpha:
        ext += [("Texture2D", f"{T}{tex}_normal.jpg"), ("Texture2D", f"{T}{tex}_rough.jpg")]
    if metal_tex:
        ext.append(("Texture2D", f"{T}{tex}_metal.jpg"))
    lines = [f'[gd_resource type="StandardMaterial3D" load_steps={len(ext) + 1} format=3]', ""]
    for i, (t, p) in enumerate(ext):
        lines.append(f'[ext_resource type="{t}" path="{p}" id="{i + 1}"]')
    lines += ["", "[resource]", f"albedo_color = Color({color})", 'albedo_texture = ExtResource("1")']
    if alpha:
        lines += ["transparency = 2", "alpha_scissor_threshold = 0.5", "cull_mode = 2", "roughness = 0.6", "metallic = 0.7"]
    else:
        lines += ['roughness_texture = ExtResource("3")', "normal_enabled = true", 'normal_texture = ExtResource("2")']
        if metal_tex:
            lines += ["metallic = 1.0", 'metallic_texture = ExtResource("4")']
    lines += [f"uv1_scale = Vector3({scale}, {scale}, {scale})", "uv1_triplanar = true", "uv1_world_triplanar = true",
              "texture_filter = 5"]
    if extra:
        lines.append(extra)
    open(OUT + name + ".tres", "w").write("\n".join(lines) + "\n")


standard("concrete_wall", "concrete_wall", 0.35)
standard("concrete_floor", "concrete_floor", 0.3)
standard("rock", "rock", 0.25)
standard("cinder_block", "cinder_block", 0.35)
standard("wood", "wood", 0.8, extra="uv1_world_triplanar = false")
standard("dark_wood", "wood", 0.8, color="0.55, 0.45, 0.4, 1")
standard("rusty_metal", "rusty_metal", 0.6, metal_tex=True, extra="uv1_world_triplanar = false")
standard("asphalt", "asphalt", 0.2)
standard("lino_floor", "lino_floor", 0.45)
standard("ground", "ground", 0.25)
standard("chainlink", "chainlink", 1.5, alpha=True)


def shader_mat(name, shader, params):
    tex = sorted({v for v in params.values() if isinstance(v, str) and v.startswith("tex:")})
    lines = [f'[gd_resource type="ShaderMaterial" load_steps={len(tex) + 2} format=3]', "",
             f'[ext_resource type="Shader" path="res://assets/shaders/{shader}.gdshader" id="1"]']
    ids = {}
    for i, t in enumerate(tex):
        ids[t] = str(i + 2)
        lines.append(f'[ext_resource type="Texture2D" path="{T}{t[4:]}" id="{i + 2}"]')
    lines += ["", "[resource]", 'shader = ExtResource("1")']
    for k, v in params.items():
        val = f'ExtResource("{ids[v]}")' if isinstance(v, str) and v.startswith("tex:") else v
        lines.append(f"shader_parameter/{k} = {val}")
    open(OUT + name + ".tres", "w").write("\n".join(lines) + "\n")


def set_(prefix, tex):
    return {f"{prefix}_albedo": f"tex:{tex}_albedo.jpg", f"{prefix}_normal": f"tex:{tex}_normal.jpg",
            f"{prefix}_rough": f"tex:{tex}_rough.jpg"}


shader_mat("terrain", "terrain", {**set_("ground", "ground"), **set_("floor", "concrete_floor"),
           **set_("wall", "cinder_block"), **set_("ceiling", "concrete_wall")})
shader_mat("painted_wall", "painted_wall", {"albedo_tex": "tex:plaster_albedo.jpg", "normal_tex": "tex:plaster_normal.jpg",
           "rough_tex": "tex:plaster_rough.jpg"})

# Glowing bits for light fixtures (each flickering light gets its own copy at runtime).
open(OUT + "bulb.tres", "w").write("""[gd_resource type="StandardMaterial3D" format=3]

[resource]
albedo_color = Color(1, 0.92, 0.75, 1)
emission_enabled = true
emission = Color(1, 0.85, 0.6, 1)
emission_energy_multiplier = 4.0
""")
open(OUT + "tube.tres", "w").write("""[gd_resource type="StandardMaterial3D" format=3]

[resource]
albedo_color = Color(0.85, 1, 0.92, 1)
emission_enabled = true
emission = Color(0.75, 1, 0.85, 1)
emission_energy_multiplier = 3.0
""")
print("materials written")
