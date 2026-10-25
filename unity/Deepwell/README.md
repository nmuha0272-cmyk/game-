# Deepwell: Unity version

This is the Unity port of the Godot game in the folder above (the Godot
version stays the main, working game, like the Unreal port in `unreal/`).
It's moved over **one phase at a time**.

| Phase | What works in Unity | Status |
|---|---|---|
| U1 | Chapter 1 built from the Godot level (all rooms, props, lights, signs, fog), walk / sprint / crouch / jump, flashlight, doors | done |
| U2 | **Better graphics** (glow, film look, shadows, quality settings), **online co-op** (Host / Join, up to 4), **items** (batteries, flares, medkits, keycards...), **story notes and tapes**, **the Long Man** (patrol, sight, hearing, chase, opens doors), **checkpoints**, **story messages**, **the 4 characters and their abilities**, sounds, settings, **sets itself up** | done |
| **U2.5** | **The Deepwell car home screen** (car on the forest road, choose your character inside the car), **the newspaper intro**, **the chapter intro**, **the trunk scene** at the team's car by the station (Eli and Cole take the pistols, talk about the missing people, Eli shows the old photo of his mom and dad), **the team's talk**, **pistols** (click to shoot, R to reload; a hit stuns the Long Man), **real textures instead of silver** | **← now** |
| U3 | Puzzles (keypads, levers, fuses, generators...), locked doors that need keycards | next |
| U4 | Downed / help up, hiding in lockers, the reveal cutscene | |
| U5 | Chapter 2 | |
| U6 | The Deepwell car menu, animations | |

Until U3, **puzzle doors and locked doors start open**, so you can walk the
whole chapter.

## What you need (one time)

1. **Unity Hub** from unity.com/download.
2. In Unity Hub → **Installs** → **Install Editor** → **Unity 6 (LTS)**.

## First time opening it

1. In Unity Hub click **Add** → **Add project from disk** and pick this
   `unity/Deepwell` folder. (If it asks which Unity version, pick your Unity 6.)
2. Open it and wait. The first time takes a few minutes: Unity downloads the
   **glTFast** package (it reads the level file) and imports everything.
3. The project **sets itself up**: it opens the **Deepwell** scene and copies
   the character models from the Godot folder. (If anything looks wrong, use
   the **Deepwell** menu at the top → **Set Up Project**.)
4. Press **Play** (the ▶ button at the top middle).

You don't need to change any settings (the old "Active Input Handling" step
is gone: the game works with either input setting).

If there are red errors in the **Console** window, copy them to Claude.

## Adding assets (Unity Asset Store and others)

Download or import an asset the normal way (Window > Package Manager > My
Assets > Download > Import). The game **puts it in the right place by
itself**: it looks at each new model's name and fills the matching slot, and
the Console says what went where, for example
`PISTOL <- Assets/LowPolyGuns/Prefabs/Glock17.prefab`.

| Slot | Used for | Names it looks for |
|---|---|---|
| Pistol | Eli's and Cole's pistol in your hand, in the trunk, pistols on the floor | pistol, handgun, glock, beretta, 1911, colt, 9mm |
| Revolver / Shotgun / SMG / Rifle | guns on the floor | revolver, shotgun, mp5, uzi, rifle, ak47, m4 |
| Flashlight | the flashlight in your hand | flashlight |
| Battery, Flare, Medkit, Keycard, Fuse, Crowbar, Gas mask, Walkie, Reel tape, Ammo, Backpack, Pouch, Fuel can, Car battery | items on the floor | the item's name (medkit, first aid, keycard, gas mask, jerry can...) |
| Notes | notes, files and posters | note, paper, document, letter, folder, clipboard |
| Doors | every door | door |
| The Long Man | the monster | long man, slender, creature, monster |

Until a slot is filled, the game shows its simple placeholder shape.

**Change a slot yourself:** top menu **Deepwell > Asset Slots**. Drag any
prefab or model onto a slot, use **Turn** if it faces the wrong way and
**Size** if it's too big or small, or **Clear** to go back to the
placeholder. **Find assets in my project now** checks everything you already
have.

## Playing online with friends

- **Host:** menu → **HOST ONLINE GAME** → pick a character. The top of your
  screen shows your IP address (also on the Esc pause screen). Tell your
  friends that number.
- **Join:** menu → **JOIN ONLINE GAME** → pick a character → type the
  host's IP → **CONNECT**.
- Same Wi-Fi/house: it just works.
- Over the internet: the host forwards **port 7777 (UDP)** on their router,
  or everyone installs a free "virtual LAN" app (**Radmin VPN** or
  **ZeroTier**), joins the same network, and uses that app's IP.
- Windows may ask "Allow Unity on networks?" the first time: click **Allow**.
- To test alone: build the game (File → Build Profiles → Build), run the
  built game and host there, then press Play in Unity and join `127.0.0.1`.

## Controls

WASD move, mouse look, Shift sprint (uses stamina), Ctrl or C crouch, Space
jump, F flashlight (uses battery), E use / pick up / read, 1 put in a
battery, 2 throw a flare, Q your ability, Tab your bag, left click shoot
(if you have a pistol), R reload, Esc pause. In cutscenes: Space = next,
hold Space = skip.

| Character | Ability (Q) |
|---|---|
| Eli | **Sense**: see the Long Man and your friends through walls for 6 s |
| Cole | **Strength**: hold Q on a closed door to hold it shut; the Long Man can't open it. Cole is a bit slower and louder |
| Nora | **Camera flash**: stuns the Long Man for a few seconds if he's in front of you |
| Walter | **Repair**: hold Q at a broken, flickering light to fix it |

The Long Man wakes up when someone walks into the "RUN!" spot in the
tunnels. Crouch and turn your flashlight off to stay hidden; running is
loud. If he catches you, you go back to the last checkpoint (a medkit saves
you once).

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
| `SZMenuScene` | The car home screen: road, forest, car, the 4 characters in their seats, the drive to the station and the arrival cutscene |
| `SZCutscene` | Camera cutscenes with captions (chapter intro, the team's talk, the Long Man's reveal) |
| `SZTrunkScene` | The trunk scene at the team's car: the lid, the pistols, Eli's photo, the camera |
| `SZAssetSlots` / `Editor/SZAssetSlotsEditor` | Asset slots: downloaded models replace the placeholders (filled by name automatically) |
| `SZGame` | Starts everything (no scene setup needed), the menus, the HUD, reading notes |
| `SZWorld` | One chapter being played: doors, items, notes, triggers, checkpoints, the Long Man, other players, and keeping everyone in sync online |
| `SZNet` | Online: Host / Join over UDP port 7777 (no extra packages) |
| `SZLevelBuilder` | Builds the level: model + colliders, lights, signs, fog |
| `SZLevelData` | The shape of the JSON file |
| `SZPlayer` | You: moving, stamina, flashlight battery, items, abilities, getting caught |
| `SZRemotePlayer` | Another player in an online game |
| `SZMonster` | The Long Man's brain (patrol, see, hear, chase, doors, stun) |
| `SZItems` | Items on the floor, your inventory, thrown flares |
| `SZLore` | Notes, files, posters you can read |
| `SZDoor` | A door that swings open and shut |
| `SZCharacters` | The 4 characters and loading their models |
| `SZGraphics` | Quality settings and the camera effect (`Resources/Shaders/SZHorrorPost.shader`) |
| `SZAudio` | Sounds (the Godot project's .wav files, in `Resources/Audio`) |
| `SZInput` | Keyboard and mouse, whichever input setting the project has |
| `SZLightEffects` | Flickering and pulsing lights, signs that face you |
| `Editor/SZSetup` | Sets the project up the first time, and the Deepwell menu |

## Known limits in U2

- It was written without Unity open (the code was checked with a C#
  compiler against Unity's code library, but not run). Expect a few
  problems the first time: send the red Console errors to Claude.
- Brightness was guessed. Light strength is `EnergyToIntensity` in
  `SZLevelBuilder.cs`; the camera look (exposure, glow, grain, vignette) is
  at the top of `SZPostEffect` in `SZGraphics.cs`. Settings → Graphics LOW
  turns the camera effect off.
- Online play has no password; only share your IP with friends.
- The Built-in renderer is used (simple, and works on any PC). URP/HDRP can
  come later.
