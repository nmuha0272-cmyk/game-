"""Build scenes/monsters/the_wired.tscn from the Long Man scene.

The Wired is the Chapter 2 monster. It walks upright (no all-fours body) and
its counter to hiding players is OVERLOAD: it feels the current in a hidden
body from further away and floods the locker instead of dragging them out.

Rather than hand-maintain a near-duplicate scene, we derive it from
long_man.tscn:
  - rename the root to TheWired
  - set hiding_counter = 2 (HidingCounter.OVERLOAD) and tune its speed
  - delete the whole CrawlBody subtree
  - recolour the skin/gown cold and make the eyes and aura electric blue
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "scenes", "monsters", "long_man.tscn")
DST = os.path.join(ROOT, "scenes", "monsters", "the_wired.tscn")


def set_material(text, mat_id, **props):
    """Set (or add) key = value lines inside a StandardMaterial3D sub-resource."""
    pattern = re.compile(
        r'(\[sub_resource type="StandardMaterial3D" id="%s"\]\n)(.*?)(\n\n)'
        % re.escape(mat_id),
        re.S,
    )
    match = pattern.search(text)
    if not match:
        raise SystemExit(f"material {mat_id} not found")
    body = match.group(2)
    for key, value in props.items():
        line = rf"^{re.escape(key)} = .*$"
        if re.search(line, body, re.M):
            body = re.sub(line, f"{key} = {value}", body, flags=re.M)
        else:
            body += f"\n{key} = {value}"
    return text[: match.start(2)] + body + text[match.end(2) :]


text = open(SRC).read()

# 1. Root: new name + the OVERLOAD hiding counter, and a slightly different gait.
text = text.replace(
    '[node name="LongMan" type="CharacterBody3D"]',
    '[node name="TheWired" type="CharacterBody3D"]\n'
    "hiding_counter = 2\n"
    "hiding_check_radius = 2.5\n"
    "patrol_speed = 1.7\n"
    "chase_speed = 4.0",
)

# 2. No all-fours body: it always walks upright. Drop CrawlBody and everything
#    under it (the next top-level node is SenseGlow).
start = text.index('[node name="CrawlBody"')
end = text.index('[node name="SenseGlow"')
text = text[:start] + text[end:]

# 3. Cold, water-damaged metal skin with a faint current running through it.
text = set_material(
    text,
    "Mat_skin",
    albedo_color="Color(0.34, 0.44, 0.5, 1)",
    emission_enabled="true",
    emission="Color(0.12, 0.36, 0.55, 1)",
    emission_energy_multiplier="0.55",
)
text = set_material(text, "Mat_gown", albedo_color="Color(0.18, 0.2, 0.25, 1)")

# 4. Electric-blue eyes and aura.
text = set_material(
    text,
    "Mat_eye",
    albedo_color="Color(0.72, 0.92, 1, 1)",
    emission="Color(0.35, 0.8, 1, 1)",
    emission_energy_multiplier="12.0",
)
text = set_material(text, "Mat_glow", albedo_color="Color(0.3, 0.7, 1, 0.45)")

# 5. Keep the scene header's step count honest.
exts = len(re.findall(r"^\[ext_resource ", text, re.M))
subs = len(re.findall(r"^\[sub_resource ", text, re.M))
text = re.sub(
    r"^\[gd_scene load_steps=\d+ format=3\]",
    f"[gd_scene load_steps={exts + subs + 1} format=3]",
    text,
    count=1,
    flags=re.M,
)

open(DST, "w").write(text)
print(f"the wired written, {len(text.splitlines())} lines")
