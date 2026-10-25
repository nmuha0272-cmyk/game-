# Plan: Placeholder menu car, hero cutscene car, and starting at the main building

## Goal

Three connected changes to the opening of the game:

1. The car on the main menu is a simple blockout placeholder, not the detailed car.
2. The detailed "real" car is used where the camera is close — character select and the arrival/trunk cutscene.
3. After the player picks a character, the car drives through the gate and parks at the **front entrance of the main building**. Chapter 1 then starts there (spawns, parked car, trunk scene, and first beat), not outside the gate.

The plan is written for **Unity** (the current build) with a **Godot parity** section, because the repo keeps both engines in step.

---

## Current behaviour

| Step | Unity | Godot |
| --- | --- | --- |
| Home / title | `SZMenuScene` builds a full car from primitives (`BuildCar`, `SZMenuScene.cs:447`) in front of the gate | `main_menu_car.gd` builds the same car (`_build_car`, `main_menu_car.gd:647`) |
| Character select | Camera sits inside the car with live character portraits | Same, `enter_select` (`main_menu_car.gd:289`) |
| Depart | `StartArrival` (`SZMenuScene.cs:105`) | `_start_arrival` (`main_menu_car.gd:344`) |
| Drive | Station slides past; stop at `StationStopZ = -9f`, i.e. at the **gate**, not the building | Station slides; stop at `STATION_STOP_Z := -9.0` (`main_menu_car.gd:45`) |
| Hand-off | Fade + callback → `SZGame.StartChapter()` loads the level | Fade → `main.gd` swaps to the chapter scene |
| Chapter 1 start | `spawns` at `z = 45`, `team_car` at `z = 43.6` — outside the gate | `Spawn1..4` at `z = 45` (`chapter_1.tscn:10585`), `Exterior/TeamCar` at `z = 43.6` (`chapter_1.tscn:2231`) |
| First beat | Walk to gate, lift/jam it with the crowbar, then cross the yard to `FrontDoor` at `z = 0` | Same gate puzzle (`chapter_1.tscn:2602`, `2623`), yard checkpoint at `z = 17`, mentor intro trigger at `(8, 0.5, 15)` (`chapter1_narrative.gd:24`) |
| Trunk scene | `SZTrunkScene` uses the level car model and builds only the lid + pistols | `opening_dialogue.gd:607` walks Eli and Cole to `../Exterior/TeamCar` |

The menu camera is far away, so a blockout car reads fine there. The select camera and the trunk cutscene are close, so those need the detailed car.

---

## Change 1 — Placeholder car on the main menu

**Decision:** keep two car builders and swap them by state.

- **Placeholder car** — used for the title/home exterior. Body, cabin, four wheels, two headlights, bumper. No interior, no seats, no glass, no badges. One flat material with a distinct silhouette colour so it is obviously a stand-in.
- **Hero car** — the current detailed build (seats, pillars, glass, lights, trunk lid, pistols). Used for character select (camera is in the back seat), the arrival drive, and the hand-off to the trunk cutscene.

### Unity (`Assets/Scripts/SZMenuScene.cs`)

1. Rename the current `BuildCar()` body to `BuildHeroCar()` and return the root.
2. Add `BuildPlaceholderCar()` (~10 primitives, no interior) at the same position/rotation so the menu framing does not change.
3. Build the placeholder in `BuildEnvironment()`.
4. In `EnterSelect()` (`SZMenuScene.cs:93`): destroy the placeholder, build the hero car, and move the select camera into it (the existing camera offsets already match the detailed car).
5. In `BackToMenu()` (`SZMenuScene.cs:99`): destroy the hero car and rebuild the placeholder.
6. `StartArrival()` keeps the hero car; it is the car the cutscene hands off to.
7. Guard against double-builds (null/`activeSelf` checks) so a quick select/back toggle cannot stack cars.

### Godot (`scenes/main_menu/deepwell/main_menu_car.gd`)

1. Split `_build_car()` (`:647`) into `_build_placeholder_car()` and `_build_hero_car()`.
2. Place the placeholder in `_ready()`; in `enter_select()` (`:289`) free it and build the hero car.
3. On state return to `MENU`, free the hero car and rebuild the placeholder.
4. Keep the arrival/trunk hand-off pointing at the hero car root.

### Asset slot (optional, recommended)

Add a `team_car` slot to the asset-slot list (`SZAssetSlots.cs` / Godot equivalent) so a downloaded car model can replace the **hero** car later. The menu placeholder never uses the slot.

---

## Change 2 — Drive all the way to the main building

Today the car stops with the gate still in front of it. It should continue up the drive and stop at the front steps, with the building filling the windshield.

### Unity (`SZMenuScene.cs`)

- `StationStopZ`: `-9f` → **`+13f`** (start tuning value). The station building front sits at local `z = -22`, the gate at `z = 0`, and the car front is about `z = -2.4`, so this puts the bumper at the steps.
- Shorten the run to keep the cutscene length: `StationStartZ` `-75f` → **`-45f`**, or raise `DriveSpeed` from `17f` to ~`20f`. Pick one after seeing it in-engine.
- `UpdateArrival()` (`:195`): keep the two-phase motion (cruise, then brake). Ensure the stop uses the new value and the fade timer still starts on arrival.
- Arrival camera (`ArriveCamPos` / `ArriveCamTarget`): currently aimed at the gate. Re-aim at the front doors and the top of the building — camera up and to the right of the car, target around the door frame at roughly `y = 3` (tune by eye).
- Headlights: keep them on so the facade is lit as the car pulls up.
- Gate: the station is moving, not the car, so the gate slides past. No collision change needed; verify the gate does not clip the camera during the pass.
- The fade should happen at the building, not mid-drive (`FadeAt` is relative to stop time, so it follows automatically).

### Godot (`main_menu_car.gd`)

- `STATION_STOP_Z` (`:45`): `-9.0` → **`13.0`**.
- Mirror the shortened run (`_start_arrival` / speed constant) and re-aim the arrival camera in `_update_arrival` (`:357`).
- `_build_station()` (`:567`) already puts the gate at the front; no geometry change.

### Environment

- Add a short gravel/asphalt apron from the gate to the front steps in both scenes so the car has something to park on (the menu station currently ends at grass). Keep it low-poly and use the existing road material.
- Keep the gate/trees outside the camera frustum at the stop; if they crowd the shot, hide the nearest tree row only during `ARRIVING` (never in gameplay).

---

## Change 3 — Chapter 1 starts at the main building

The chapter's own frame is: `FrontDoor` at `z = 0`, the gate at `z = 22`, and the old spawn at `z = 45`. "Start at the building" means moving the spawn and the parked car into the porch/driveway area and relocating the first beat.

### New start layout (starting values)

| Thing | Old | New |
| --- | --- | --- |
| Player spawns | `(±1.5, 0, 45)` / `(±1.5, 0, 46.5)` | `(±1.5, 0, 7.5)` / `(±1.5, 0, 9.0)`, facing `-Z` (the doors) |
| `team_car` | `(-8.4, 0, 43.6)`, 90° | `(-5.5, 0, 9.0)`, nose toward the doors, trunk facing the spawns |
| Mentor intro trigger | `(8, 0.5, 15)` | porch, e.g. `(2.5, 0.5, 4.5)` |
| Crowbar | yard marker `(8, 0.2, 15.5)` | in the **trunk** with the pistols (see below) |
| Yard checkpoint `z = 17` | on the walk in | remove or repurpose as the porch checkpoint |

### The gate puzzle

The gate lift/clamp is the current tutorial and it sits between the old spawn and the door. Starting at the building would skip it. **Recommended fix:** move the beat to the front door and keep the tutorial verbs.

- Make `FrontDoor` a `JAMMED` door lock (`door_lock.gd` already supports this: crowbar, 3 s pry, loud, breaks the crowbar).
- Put the crowbar in the trunk scene, next to the pistols, so the cutscene that already happens at the car hands the team both tools.
- After the trunk scene, the team walks to the chained front door, one player pries it (noise draws attention), and the chapter continues inside. This is the same "loud entry" beat, just at the building instead of the yard.
- Leave the yard gate and its puzzle in the scene as an optional side route/lore stash for now; do not delete geometry in the same change. (Follow-up: remove or repurpose it once the new opening is signed off.)

Alternative if the gate must stay mandatory: park the car at the gate and walk in, but that contradicts "the building is where the game starts", so it is not the recommended path.

### Unity implementation

- `Assets/Resources/Levels/chapter1.json`: update `spawns` and `team_car` to the table above; set `FrontDoor.locked` to `true` and add the pry/crowbar flag on that door; move or remove the yard checkpoint that guards `z = 17`; move the crowbar pickup into the `team_car` trunk item list.
- `SZWorld.cs`: nothing structural — it spawns from `spawns` and builds `SZTrunkScene` from `Data.team_car`, so both move with the JSON.
- `SZTrunkScene.cs`: no position edits needed (it works in car-local space). Verify the trunk opens toward the spawn side; rotate `team_car` instead of editing the cutscene.
- `SZCutscene.cs`: the intro camera path starts from the spawn, so retarget its first/last points to the porch and the front door.
- Gate logic/`gate` entries in the JSON: keep them valid but out of the critical path.

### Godot implementation

- `chapter_1.tscn`:
  - `Spawn1..4` transforms (`:10585`–`10595`) → porch positions above, rotated 180°.
  - `Exterior/TeamCar` (`:2231`) → new parked transform.
  - Remove the duplicate yard car (`Exterior/CarBody` `:2175`, `CarCabin` `:2181`, the four `Wheel*` and `Windshield`) or move it with `TeamCar`. Two cars outside the gate would be visible from the porch. Recommended: delete the duplicate and keep the detailed `TeamCar`.
  - `Puzzles/FrontDoor` (`:3219`): add a `DoorLock` child with `kind = JAMMED`.
  - Move the `crowbar_161` marker (`:2558`) into the car trunk (or spawn it via the trunk dialogue).
  - Move/remove the yard checkpoint and the `Gate*` puzzle trigger so nothing fires at the old spawn.
- `scripts/chapters/chapter1_narrative.gd:24`: move the `MENTOR_INTRO` trigger to the porch.
- `scripts/chapters/opening_dialogue.gd:607`: the trunk walk already targets `../Exterior/TeamCar`, so it follows the car. Add the crowbar hand-out line here.
- `scripts/main.gd` / chapter loading: no change; the chapter path is the same.

### Multiplayer

- Spawns and `team_car` are host-side data; changing positions needs no replication change.
- The trunk cutscene and the pry are host-authoritative already (`SZTrunkScene`, `door_lock.gd`). Confirm every client sees the trunk scene at the parked car (it is triggered by the host after arrival).
- Re-test 2-player spawn overlap: the new porch is tighter than the 45 m field. Keep at least 2 m between spawn markers and check no player spawns inside the car collider.

---

## Acceptance criteria

- [ ] Title screen shows a clearly blocky placeholder car at the old menu position; no missing parts, no console errors.
- [ ] Selecting a character swaps in the detailed car before the select camera looks at the interior; going back restores the placeholder without stacking.
- [ ] After "PLAY AS", the car drives through the gate and stops at the main building steps; the camera frames the building, not the road.
- [ ] Skip still works during the drive and fades at the building.
- [ ] Chapter 1 loads with all players on the porch facing the front doors.
- [ ] The detailed team car is parked beside them, trunk toward the group.
- [ ] The trunk scene plays at the parked car and hands out the pistols; the crowbar is available for the front door.
- [ ] The front door pries open with the crowbar, makes noise, and leads into the foyer as before.
- [ ] No soft-lock: no required item, trigger, or checkpoint is left behind at the old gate spawn.
- [ ] Host + 1 client both see the same arrival, spawn, and trunk scene.
- [ ] No new warnings in the Unity console or Godot output.

## Test checklist

1. Unity: play from the boot scene, wait through the title, select each of the four characters, confirm the car swap and camera.
2. Let the arrival play fully; repeat with Skip.
3. Confirm the first chapter frame (spawn positions, car, door prompt).
4. Play the trunk scene; confirm the pistols and crowbar.
5. Pry the front door; confirm the noise and the transition inside.
6. Repeat 1–5 in Godot (`main.tscn` → menu → chapter).
7. Two-player host/client pass over the same steps.
8. Walk the old yard route and confirm the gate area is still traversable and has no orphaned triggers.

## Files to touch

| File | Change |
| --- | --- |
| `unity/Deepwell/Assets/Scripts/SZMenuScene.cs` | split car builders, stop at building, arrival camera |
| `unity/Deepwell/Assets/Scripts/SZWorld.cs` | verify spawn/trunk wiring after JSON move |
| `unity/Deepwell/Assets/Scripts/SZTrunkScene.cs` | verify trunk side, add crowbar hand-out |
| `unity/Deepwell/Assets/Scripts/SZCutscene.cs` | retarget intro camera to porch/door |
| `unity/Deepwell/Assets/Resources/Levels/chapter1.json` | spawns, `team_car`, front-door lock, crowbar, checkpoint |
| `unity/Deepwell/Assets/Scripts/SZAssetSlots.cs` | optional `team_car` slot |
| `scenes/main_menu/deepwell/main_menu_car.gd` | split car builders, `STATION_STOP_Z`, arrival camera |
| `scenes/chapters/chapter_1/chapter_1.tscn` | spawns, `TeamCar`, duplicate car removal, front-door lock, crowbar |
| `scripts/chapters/chapter1_narrative.gd` | move mentor intro trigger |
| `scripts/chapters/opening_dialogue.gd` | crowbar hand-out |
| `GAME_PLAN.md` | update the opening flow description |

## Open questions

1. Should the yard gate puzzle be deleted after the new opening is approved, or kept as an optional side route?
2. Should the placeholder car also be used for the character-select state, or is the detailed interior required there? (Recommended: keep the detailed interior.)
3. Do we want a real downloaded car model in the `team_car` slot now, or leave the primitive hero car until art is ready?
