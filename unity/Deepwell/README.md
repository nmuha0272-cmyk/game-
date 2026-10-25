# Deepwell: Unity version

This is the Unity port of the Godot game in the folder above (the Godot
version stays the main, working game, like the Unreal port in `unreal/`).
It's moved over **one phase at a time**.

| Phase | What works in Unity | Status |
|---|---|---|
| **U1** | Chapter 1 built from the Godot level (all rooms, props, lights, signs, fog), walk / sprint / crouch / jump, flashlight, doors | **← now** |
| U2 | Online co-op: Host / Join (Netcode for GameObjects), players see each other | next |
| U3 | Items + inventory, puzzles (keypads, levers, fuses, generators...), story files | |
| U4 | The Long Man (patrol, chase, catching), downed / help up, checkpoints | |
| U5 | The characters and their abilities | |
| U6 | Polish: sounds, materials, the Deepwell car menu | |

Until U3, **puzzle doors and locked doors start open**, so you can walk the
whole chapter.

## What you need (one time)

1. **Unity Hub** from unity.com/download.
2. In Unity Hub → **Installs** → **Install Editor** → **Unity 6 (LTS)**.

## First time opening it

1. In Unity Hub click **Add** → **Add project from disk** and pick this
   `unity/Deepwell` folder. (If it asks which Unity version, pick your Unity 6.)
2. Open it. The first time takes a while: Unity downloads the **glTFast**
   package (it reads the level file) and imports everything.
   - If the Console says glTFast is missing: **Window → Package Manager → +
     → Add package by name** → `com.unity.cloud.gltfast` → Add.
3. **Edit → Project Settings → Player → Other Settings → Active Input
   Handling** → choose **Both** (or **Input Manager (Old)**). Unity restarts.
4. Open any scene (the empty "SampleScene" is fine) and press **Play**.
   The game builds itself: you get the DEEPWELL menu → **PLAY CHAPTER 1**.

If there are red errors in the **Console** window, copy them to Claude.

## Controls

WASD move, mouse look, Shift sprint, Ctrl or C crouch, Space jump, F
flashlight, E open/close doors, Esc pause.

## How it works (for learning)

- `Assets/Resources/Levels/chapter1_level.glb` is the whole level model,
  and `chapter1.json` holds the lights, doors, signs, spawn points and extra
  colliders. Both are made from the Godot level by `tools/export_for_unity.gd`,
  so **change the level in Godot** (`tools/make_chapter1.py`), re-export, and
  both versions match. Re-export (from the main folder, with Godot 4.7):
  `godot --headless -s tools/export_for_unity.gd`
- `Assets/Scripts/` is the C# code, one job per file:

| File | Job |
|---|---|
| `SZGame` | Starts everything (no scene setup needed), the menu, Esc pause |
| `SZLevelBuilder` | Builds the chapter: level model + colliders, lights, doors, signs, fog |
| `SZLevelData` | The shape of the JSON file |
| `SZPlayer` | The player: walking, crouching, jumping, mouse look, flashlight, pressing E |
| `SZDoor` | A door that swings open and shut |
| `SZLightEffects` | Flickering and pulsing lights, signs that face you |

## Known limits in U1

- Nothing here has been compiled yet (it was written without Unity
  available). Expect a few errors the first time: send them to Claude.
- Brightness was guessed. Light strength is `EnergyToIntensity` in
  `SZLevelBuilder.cs`; fog is in `BuildEnvironment`.
- The level uses Unity's Built-in renderer (the simplest). URP/HDRP come later
  if we want fancier graphics.
