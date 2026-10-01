# Subject Zero: Unreal Engine 5 version

This is the Unreal port of the Godot game in the folder above. It's being
moved over **one phase at a time**. The Godot version stays the main,
working game until this one catches up.

| Phase | What works in Unreal | Status |
|---|---|---|
| **U1** | Chapter 1 built automatically, Host/Join over the network, walk, sprint, crouch, flashlight, doors | **← now** |
| U2 | Items + inventory, keycard door, lore notes and the journal | next |
| U3 | Puzzles: hold switches, gate, keypad + monitor code, vent, fuses, generator, launch keys, elevator ending | |
| U4 | The Long Man (patrol, chase, catching), downed / help up, checkpoints | |
| U5 | The four characters and their abilities | |
| U6 | Real materials and textures, sounds, polish | |

Until U3, **puzzle doors and the gate start open**, so you can walk through
the whole chapter.

## What you need (one time)

1. **Unreal Engine 5.4** from the Epic Games Launcher (Unreal Engine tab →
   Library → +). 5.5 should work too.
2. **Visual Studio 2022 Community** (free), from visualstudio.microsoft.com.
   In the installer tick **"Game development with C++"**. In the right-hand
   list also tick **"Unreal Engine installer"** and a **Windows 10/11 SDK**.

## First time opening it

1. Download this repo and go to `unreal/SubjectZero/`.
2. Right-click `SubjectZero.uproject` → **Generate Visual Studio project
   files**. (If that option isn't there, skip it.)
3. Double-click `SubjectZero.uproject`. It says the **SubjectZero** module is
   missing or was built with a different version: click **Yes** to build it.
   This takes a few minutes the first time.
   - **If it fails:** it tells you to build from source. Open
     `SubjectZero.sln` in Visual Studio, press **Ctrl+Shift+B**, and copy
     the errors from the **Error List** (or the Output window) to Claude.
4. The editor opens with an empty level. Make the map the game uses:
   **File → New Level → Empty Level**, then **File → Save Current Level As**
   → open the `Maps` folder → name it **`Chapter1`** → Save.
5. Press **Play** (the green ▶ at the top). The whole chapter builds itself
   when the game starts. The editor view stays empty; that's normal.

## Playing

- **In the editor, solo:** press Play, then click **Host** in the menu.
- **In the editor, 2 players:** click the **⋮** next to Play → set
  **Number of Players = 2** and **Net Mode = Play As Listen Server** → Play.
  Two windows open, already connected.
- **A real game you can send to friends:** **Platforms → Windows → Package
  Project**, then pick a folder. Run `SubjectZero.exe` from there. One
  person clicks **Host**; the others type the host's IP and click **Join**
  (same as the Godot version: port 7777, same Wi-Fi or a VPN like Tailscale).

Controls: WASD move, mouse look, Shift sprint, Ctrl or C crouch, Space jump,
E open/close doors, F flashlight, Esc leave the game.

## How it works (for learning)

- `Content/Data/chapter1.json` is the whole level: every wall, light, tree,
  door and spawn point. It's made from the Godot level by
  `tools/export_for_unreal.gd`, so **change the level in Godot**
  (`tools/make_chapter1.py`), re-export, and both versions match.
  Re-export command (from the main folder):
  `godot --headless -s tools/export_for_unreal.gd`
- `Source/SubjectZero/` is the C++ code. One job per file, like the Godot scripts:

| File | Job |
|---|---|
| `SZWorldBuilder` | Reads chapter1.json and builds the level when it starts (the rock with the tunnels cut out, walls, lights, trees, signs, fog, camera look) |
| `SZGameMode` | The host's rules: which classes to use, where players spawn |
| `SZPlayerController` | The main menu (Host / Join / Quit) and Esc to leave |
| `SZCharacter` | The player: walking, sprinting, crouching, flashlight, pressing E |
| `SZInteractable` | The base for anything you press E on |
| `SZDoor` | A door that swings open and shut (the host decides, everyone sees it) |
| `SZFlicker` | Makes lights flicker or pulse |
| `SZHUD` | The dot in the middle and the "[E] Open door" text |
| `SZMaterials` | Picks a material by name (see below) |

## Making it look good (real textures)

Right now everything is plain colors. To give a surface real textures:

1. Drag the images from the Godot project's `assets/textures/` (for example
   `concrete_wall_albedo.jpg`, `concrete_wall_normal.jpg`) into the
   Content Browser.
2. Right-click → **Material**, and name it `M_` plus the surface name, for
   example **`M_concrete_wall`**. Save it in a folder called **`Materials`**.
3. In the material, connect the albedo texture to Base Color and the normal
   texture to Normal. (Tip: use a **WorldAlignedTexture** node so it doesn't stretch.)

The game picks up `M_<name>` by itself next time you press Play. The surface
names are: `terrain`, `ground`, `concrete_wall`, `concrete_floor`,
`cinder_block`, `rock`, `painted_wall`, `wood`, `dark_wood`, `rusty_metal`,
`asphalt`, `lino_floor`, `chainlink`.

(Phase U6 will do this properly for all of them.)

## Known limits in U1

- Nothing in this folder has been compiled yet (it was written without
  Unreal available). Expect a few build errors the first time. Send them to
  Claude and they'll get fixed.
- The chain-link fence is solid until it gets a see-through material (U6).
- Brightness was guessed. Light strength is `EnergyToCandela` in
  `SZWorldBuilder.cpp`; fog, film grain and dark corners are in
  `BuildAtmosphere`.
