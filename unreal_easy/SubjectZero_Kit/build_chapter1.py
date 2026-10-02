"""
SUBJECT ZERO - Chapter 1 builder for Unreal Engine (no coding needed).

How to use (inside the Unreal editor):
    Tools  ->  Execute Python Script...  ->  pick this file.
It imports the textures, makes the materials, builds the whole level, adds a
flashlight to the player, and saves the map as Content/SubjectZero/Chapter1.
Then press Play.

If something goes wrong, open  Window -> Output Log  and look for lines that
start with "[SubjectZero]". Copy them to Claude.
"""
import json
import os

import unreal

KIT = os.path.dirname(os.path.abspath(__file__))
ROOT = "/Game/SubjectZero"
TEX_PATH = ROOT + "/Textures"
MAT_PATH = ROOT + "/Materials"
MAP_PATH = ROOT + "/Chapter1"
TILE_CM = 300.0  # how big one copy of a texture is on a wall

# Materials with real textures (surface name -> texture file name).
TEXTURED = {
    "ground": "ground", "terrain": "cinder_block", "cinder_block": "cinder_block",
    "concrete_wall": "concrete_wall", "concrete_floor": "concrete_floor", "rock": "rock",
    "painted_wall": "plaster", "wood": "wood", "dark_wood": "wood", "rusty_metal": "rusty_metal",
    "asphalt": "asphalt", "lino_floor": "lino_floor",
}
TINT = {"painted_wall": (0.45, 0.55, 0.45), "dark_wood": (0.55, 0.45, 0.4)}

asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
MEL = unreal.MaterialEditingLibrary
actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
levels = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)


def log(text):
    unreal.log("[SubjectZero] " + text)


# ------------------------------------------------------------------ textures

def import_textures():
    tasks = []
    for name in sorted(os.listdir(os.path.join(KIT, "Textures"))):
        asset_name = os.path.splitext(name)[0]
        if unreal.EditorAssetLibrary.does_asset_exist(f"{TEX_PATH}/{asset_name}"):
            continue
        task = unreal.AssetImportTask()
        task.filename = os.path.join(KIT, "Textures", name)
        task.destination_path = TEX_PATH
        task.automated = True
        task.save = True
        task.replace_existing = True
        tasks.append(task)
    if tasks:
        asset_tools.import_asset_tasks(tasks)
    log(f"textures imported: {len(tasks)}")


# ------------------------------------------------------------------ materials

_materials = {}


def _new_material(name):
    path = f"{MAT_PATH}/M_{name}"
    if unreal.EditorAssetLibrary.does_asset_exist(path):
        return unreal.EditorAssetLibrary.load_asset(path), False
    return asset_tools.create_asset(f"M_{name}", MAT_PATH, unreal.Material, unreal.MaterialFactoryNew()), True


def _expr(mat, cls, x, y):
    return MEL.create_material_expression(mat, cls, x, y)


def textured_material(name, tex_name):
    """A material that wraps the texture around any box without stretching
    (it projects the texture from the three directions, using world position)."""
    mat, is_new = _new_material(name)
    if not is_new:
        return mat
    texture = unreal.EditorAssetLibrary.load_asset(f"{TEX_PATH}/{tex_name}_albedo")
    world = _expr(mat, unreal.MaterialExpressionWorldPosition, -1400, 0)
    scaled = _expr(mat, unreal.MaterialExpressionDivide, -1200, 0)
    scaled.set_editor_property("const_b", TILE_CM)
    MEL.connect_material_expressions(world, "", scaled, "A")
    normal = _expr(mat, unreal.MaterialExpressionVertexNormalWS, -1400, 400)
    absn = _expr(mat, unreal.MaterialExpressionAbs, -1200, 400)
    MEL.connect_material_expressions(normal, "", absn, "")

    total = None
    # Each direction: (which two world axes make the picture, which normal axis weights it)
    for i, (uv_mask, weight_mask) in enumerate([((True, True, False), (False, False, True)),   # floors/ceilings
                                                ((True, False, True), (False, True, False)),   # walls facing Y
                                                ((False, True, True), (True, False, False))]):  # walls facing X
        uv = _expr(mat, unreal.MaterialExpressionComponentMask, -1000, i * 250)
        uv.set_editor_property("r", uv_mask[0]); uv.set_editor_property("g", uv_mask[1]); uv.set_editor_property("b", uv_mask[2])
        MEL.connect_material_expressions(scaled, "", uv, "")
        if not uv_mask[0]:
            pass
        sample = _expr(mat, unreal.MaterialExpressionTextureSample, -800, i * 250)
        sample.set_editor_property("texture", texture)
        MEL.connect_material_expressions(uv, "", sample, "UVs")
        w = _expr(mat, unreal.MaterialExpressionComponentMask, -800, 800 + i * 120)
        w.set_editor_property("r", weight_mask[0]); w.set_editor_property("g", weight_mask[1]); w.set_editor_property("b", weight_mask[2])
        MEL.connect_material_expressions(absn, "", w, "")
        part = _expr(mat, unreal.MaterialExpressionMultiply, -550, i * 250)
        MEL.connect_material_expressions(sample, "RGB", part, "A")
        MEL.connect_material_expressions(w, "", part, "B")
        if total is None:
            total = part
        else:
            add = _expr(mat, unreal.MaterialExpressionAdd, -350, i * 250)
            MEL.connect_material_expressions(total, "", add, "A")
            MEL.connect_material_expressions(part, "", add, "B")
            total = add
    if name in TINT:
        tint = _expr(mat, unreal.MaterialExpressionConstant3Vector, -350, 700)
        r, g, b = TINT[name]
        tint.set_editor_property("constant", unreal.LinearColor(r, g, b, 1))
        tinted = _expr(mat, unreal.MaterialExpressionMultiply, -200, 300)
        MEL.connect_material_expressions(total, "", tinted, "A")
        MEL.connect_material_expressions(tint, "", tinted, "B")
        total = tinted
    MEL.connect_material_property(total, "", unreal.MaterialProperty.MP_BASE_COLOR)
    rough = _expr(mat, unreal.MaterialExpressionConstant, -350, 900)
    rough.set_editor_property("r", 0.85)
    MEL.connect_material_property(rough, "", unreal.MaterialProperty.MP_ROUGHNESS)
    MEL.recompile_material(mat)
    unreal.EditorAssetLibrary.save_loaded_asset(mat)
    return mat


def color_material(name, hex_color, glow=False):
    mat, is_new = _new_material(name)
    if not is_new:
        return mat
    c = unreal.LinearColor(int(hex_color[0:2], 16) / 255.0, int(hex_color[2:4], 16) / 255.0, int(hex_color[4:6], 16) / 255.0, 1)
    color = _expr(mat, unreal.MaterialExpressionConstant3Vector, -400, 0)
    color.set_editor_property("constant", c)
    MEL.connect_material_property(color, "", unreal.MaterialProperty.MP_BASE_COLOR)
    if glow:
        boost = _expr(mat, unreal.MaterialExpressionMultiply, -200, 200)
        boost.set_editor_property("const_b", 8.0)
        MEL.connect_material_expressions(color, "", boost, "A")
        MEL.connect_material_property(boost, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)
    MEL.recompile_material(mat)
    unreal.EditorAssetLibrary.save_loaded_asset(mat)
    return mat


def get_material(name):
    if name in _materials:
        return _materials[name]
    try:
        if name.startswith("#"):
            mat = color_material("Color_" + name[1:], name[1:])
        elif name.startswith("!"):
            mat = color_material("Glow_" + name[1:], name[1:], glow=True)
        elif name == "chainlink":
            mat = color_material("chainlink", "2a2a2a")
        else:
            mat = textured_material(name, TEXTURED.get(name, "concrete_wall"))
    except Exception as error:  # never stop the whole build over one material
        log(f"material {name} failed ({error}), using a plain one")
        mat = color_material("Fallback", "808080")
    _materials[name] = mat
    return mat


# ------------------------------------------------------------------ level

MESHES = {
    "cube": "/Engine/BasicShapes/Cube.Cube", "cylinder": "/Engine/BasicShapes/Cylinder.Cylinder",
    "sphere": "/Engine/BasicShapes/Sphere.Sphere", "cone": "/Engine/BasicShapes/Cone.Cone",
}


def vec(v):
    return unreal.Vector(v[0], v[1], v[2])


def rotation(entry):
    return unreal.MathLibrary.make_rot_from_xz(vec(entry["x"]), vec(entry["z"]))


def color(hex_color):
    return unreal.LinearColor(int(hex_color[0:2], 16) / 255.0, int(hex_color[2:4], 16) / 255.0, int(hex_color[4:6], 16) / 255.0, 1)


def build_level(kit):
    levels.new_level(MAP_PATH)
    meshes = {k: unreal.EditorAssetLibrary.load_asset(p) for k, p in MESHES.items()}
    shapes = kit["shapes"]
    with unreal.ScopedSlowTask(len(shapes), "Building Chapter 1...") as task:
        task.make_dialog(True)
        for i, s in enumerate(shapes):
            if task.should_cancel():
                break
            task.enter_progress_frame(1)
            actor = actors.spawn_actor_from_class(unreal.StaticMeshActor, vec(s["p"]), rotation(s))
            actor.set_actor_scale3d(unreal.Vector(s["s"][0] / 100.0, s["s"][1] / 100.0, s["s"][2] / 100.0))
            comp = actor.static_mesh_component
            comp.set_static_mesh(meshes[s["t"]])
            comp.set_material(0, get_material(s["m"]))
            if not s["c"]:
                comp.set_collision_profile_name("NoCollision")
                comp.set_editor_property("cast_shadow", s["t"] != "cube" or s["s"][2] > 5)
            folder = "Forest" if s["m"] in ("#0a140d", "#1f1712") else ("Rock" if s["m"] in ("ground", "cinder_block") else "Level")
            actor.set_folder_path(folder)
    log(f"shapes placed: {len(shapes)}")

    for L in kit["lights"]:
        light = actors.spawn_actor_from_class(unreal.PointLight, vec(L["p"]), unreal.Rotator())
        comp = light.point_light_component
        comp.set_mobility(unreal.ComponentMobility.MOVABLE)
        comp.set_editor_property("intensity_units", unreal.LightUnits.CANDELAS)
        comp.set_intensity(L["energy"] * 12.0)
        comp.set_attenuation_radius(L["range"])
        comp.set_light_color(color(L["color"]))
        comp.set_cast_shadows(L["shadow"])
        light.set_folder_path("Lights")
    log(f"lights placed: {len(kit['lights'])}")

    for T in kit["labels"]:
        rot = rotation(T)
        rot = unreal.Rotator(rot.roll, rot.pitch, rot.yaw + 180.0)
        label = actors.spawn_actor_from_class(unreal.TextRenderActor, vec(T["p"]), rot)
        comp = label.text_render
        comp.set_editor_property("text", T["text"])
        comp.set_editor_property("world_size", T["size"])
        comp.set_editor_property("horizontal_alignment", unreal.HorizTextAligment.EHTA_CENTER)
        c = color(T["color"])
        comp.set_editor_property("text_render_color", unreal.Color(int(c.r * 255), int(c.g * 255), int(c.b * 255), 255))
        label.set_folder_path("Signs")

    moon_dir = vec(kit["moon"]["dir"])
    moon = actors.spawn_actor_from_class(unreal.DirectionalLight, unreal.Vector(0, 0, 3000), moon_dir.rotator())
    moon.light_component.set_mobility(unreal.ComponentMobility.MOVABLE)
    moon.light_component.set_intensity(kit["moon"]["energy"] * 1.5)
    moon.light_component.set_light_color(color(kit["moon"]["color"]))

    fog = actors.spawn_actor_from_class(unreal.ExponentialHeightFog, unreal.Vector(0, 0, -1000), unreal.Rotator())
    fog_comp = fog.get_component_by_class(unreal.ExponentialHeightFogComponent)
    fog_comp.set_editor_property("fog_density", 0.03)
    fog_comp.set_editor_property("fog_height_falloff", 0.002)
    fog_comp.set_editor_property("volumetric_fog", True)

    post = actors.spawn_actor_from_class(unreal.PostProcessVolume, unreal.Vector(0, 0, 0), unreal.Rotator())
    post.set_editor_property("unbound", True)
    settings = post.get_editor_property("settings")
    for prop, value in [("vignette_intensity", 0.7), ("film_grain_intensity", 0.25), ("scene_fringe_intensity", 0.6),
                        ("auto_exposure_min_brightness", -1.0), ("auto_exposure_max_brightness", 1.0)]:
        try:
            settings.set_editor_property("override_" + prop, True)
            settings.set_editor_property(prop, value)
        except Exception as error:
            log(f"post-process {prop} skipped ({error})")
    post.set_editor_property("settings", settings)

    for i, spawn in enumerate(kit["spawns"]):
        actors.spawn_actor_from_class(unreal.PlayerStart, vec(spawn["p"]) + unreal.Vector(0, 0, 100),
                                      unreal.Rotator(0, 0, spawn["yaw"]))
    levels.save_current_level()
    log("level saved: " + MAP_PATH)


# ------------------------------------------------------------------ flashlight

def add_flashlight():
    """Gives the template's first-person character a flashlight (always on)."""
    registry = unreal.AssetRegistryHelpers.get_asset_registry()
    found = [a for a in registry.get_assets_by_class(unreal.TopLevelAssetPath("/Script/Engine", "Blueprint"))
             if "FirstPersonCharacter" in str(a.asset_name)]
    if not found:
        log("no first-person character found (did you pick the First Person template?) - skipping flashlight")
        return
    bp = unreal.EditorAssetLibrary.load_asset(str(found[0].package_name))
    subsystem = unreal.get_engine_subsystem(unreal.SubobjectDataSubsystem)
    handles = subsystem.k2_gather_subobject_data_for_blueprint(bp)
    lib = unreal.SubobjectDataBlueprintFunctionLibrary
    camera = None
    for h in handles:
        obj = lib.get_object(lib.get_data(h))
        if isinstance(obj, unreal.SpotLightComponent) and obj.get_name().startswith("Flashlight"):
            log("flashlight already added")
            return
        if isinstance(obj, unreal.CameraComponent) and camera is None:
            camera = h
    params = unreal.AddNewSubobjectParams(parent_handle=camera or handles[0], new_class=unreal.SpotLightComponent,
                                          blueprint_context=bp)
    new_handle, fail_reason = subsystem.add_new_subobject(params)
    if not fail_reason.is_empty():
        log(f"could not add flashlight: {fail_reason}")
        return
    subsystem.rename_subobject(new_handle, unreal.Text("Flashlight"))
    light = lib.get_object(lib.get_data(new_handle))
    light.set_editor_property("intensity_units", unreal.LightUnits.CANDELAS)
    light.set_editor_property("intensity", 350.0)
    light.set_editor_property("outer_cone_angle", 24.0)
    light.set_editor_property("inner_cone_angle", 10.0)
    light.set_editor_property("attenuation_radius", 2500.0)
    light.set_editor_property("relative_location", unreal.Vector(10, 15, -12))
    unreal.BlueprintEditorLibrary.compile_blueprint(bp)
    unreal.EditorAssetLibrary.save_loaded_asset(bp)
    log("flashlight added to " + str(found[0].asset_name))


# ------------------------------------------------------------------ go

def main():
    kit = json.load(open(os.path.join(KIT, "level.json")))
    log("starting")
    import_textures()
    build_level(kit)
    try:
        add_flashlight()
    except Exception as error:
        log(f"flashlight skipped ({error})")
    log("DONE! Press Play.")


main()
