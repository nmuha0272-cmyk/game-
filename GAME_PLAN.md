# GAME_PLAN.md — Working Title: "Subject Zero"

A first-person, chapter-based, 2–4 player online co-op horror game set in an abandoned
Cold War research facility. This file is the master plan for building the game
with Claude Code. Work through it **one phase at a time**.

---

## Instructions for Claude Code

- Read this whole file before writing any code.
- Build **only the current phase**. Do not skip ahead.
- After each task, explain to me (the developer) how to test it in the Godot editor.
- I am learning, so explain what each new script does in simple terms.
- Use placeholder art (gray boxes, capsules, basic lights) until Phase 8.
- Keep scripts small and focused. One job per script.
- Check off tasks in this file (`- [x]`) when they are done and tested.
- If something in this plan is unclear, ask me before guessing.

---

## Tech Stack

- **Engine:** Godot 4.x (latest stable), 3D, Forward+ renderer
- **Language:** GDScript
- **Multiplayer:** Godot high-level multiplayer (ENet), host-and-join model
  (one player hosts, others join by IP). Steam lobbies can be added later.
- **Version control:** Git (commit after every working task)

Why Godot: its scene and script files are plain text, so Claude Code can read
and edit everything directly, and multiplayer is built in.

---

## Game Summary

**Setting:** A secret 1960s research facility hidden beneath a fake weather
station. It studied "soldier enhancement." The experiments went wrong, the
lower levels were sealed with people still inside, and the site was buried.
Decades later, four people break in.

**Core loop:** Explore → find and share gear → solve co-op puzzles → survive
monster encounters → uncover story clues → descend to the next area.

**The heart of this game is TEAMWORK.** No player should be able to get
through the facility alone. Every system (abilities, gear, puzzles, monsters)
should push players to talk, split up, cover each other, and rely on each other.

**6 Chapters** — each spotlights one character and deepens the mystery.
**The Son (Eli) unlocks new powers each chapter** (Sense → Pulse → Resonance → Echo Walk → Inheritance), changing how the team tracks, fights, and survives.

**Tone:** Dark, tense, retro. Flickering fluorescent lights, bunker doors,
reel-to-reel tapes, propaganda posters, gas masks, bulky old computers.

---

## Characters

Every player picks one character. Each character can only be picked once per
game. Each has one unique ability, so the team must work together.

| Character | Role | Ability | Held Item | Starting Weapon |
|---|---|---|---|---|
| **The Son (Eli)** | Tracker | **Sense** (Ch.1): Hold to see nearby monsters glow through walls for 3s. 20s cooldown.<br>**Pulse** (Ch.2): Sonar ping reveals exact monster positions/direction 30m, 2s. 30s cooldown, loud.<br>**Resonance** (Ch.3): Mark monster weak point, +50% team damage 5s. 40s cooldown.<br>**Echo Walk** (Ch.4): Phase 2s — silent, pass through monsters, see patrol trails. 45s cooldown.<br>**Inheritance** (Ch.5): Channel parent's serum 10s — Sense always on, silent, monsters hesitate. Once/chapter, exhausts after. | Parent's dog tags | None — find one |
| **The Journalist** | Stunner / Lore | **Camera Flash:** Stuns a monster in front of her for 2 seconds. 15 second cooldown. Photographing evidence unlocks lore entries. | Old film camera | None — find one |
| **The Engineer** | Fixer | **Repair:** Hold to fix generators, elevators, broken panels, and hack locked security doors. Only he can do this. | Wrench | None — find one |
| **The Guard (Frank)** | Protector | **Strength:** Hold doors shut against monsters, move heavy objects, build barricades, carry a downed teammate. Moves slower and makes more noise. | Heavy flashlight | None — find one |

**Yes, that's right: nobody starts with a gun.** Every chapter begins unarmed.
Weapons are scavenged from the world (armories, dead security, hidden caches) —
see "Weapons and Ammunition". A looted weapon is yours only until you drop it or
go down.

**Shared by all characters:** walk, sprint (limited stamina), crouch, flashlight,
interact, pick up small items, revive downed teammates.

**Weapon slot:** 1 per player (separate from 3 gear slots). **All gunshots attract
monsters** in a large radius. No HUD ammo counter — inspect weapon to check mag.
Melee is silent but risky. Weapons/mags can be shared.

**Voice Chat:** Players within **5 meters** can talk freely (proximity chat).
**Walkie-Talkie:** Press and hold to talk to paired player at any distance.
**Using a walkie-talkie emits a sound radius that attracts monsters** — they
will investigate the transmission source.

**Downed system:** A player caught by a monster is "downed," not killed. A
teammate can revive them within 30 seconds. If everyone is downed, restart
from the last checkpoint.

---

## Teamwork Design Rules

Every level, puzzle, and encounter must follow these rules:

1. **No solo solutions.** Every puzzle needs at least 2 players to solve.
   The game is online co-op only: 2 to 4 players, no single-player mode.
2. **Everyone matters.** Each chapter must have moments where each of the four
   abilities is needed — **the Son's current power for that chapter counts as
   his ability**. If a character is missing (fewer than 4 players), provide a
   slower backup solution so the game is still beatable.
3. **Split the team.** Puzzles often put players in different rooms, so they
   must talk to each other to succeed.
4. **Cover each other.** Many tasks take time (repairing, entering codes,
   carrying items), leaving that player vulnerable while teammates guard them.
5. **Share gear.** Items are limited, so players must decide who carries what
   and pass things to each other.
6. **Reward communication.** Some information is only visible to one player
   (a code on a screen, a map on a wall), and they must describe it to others.

---

## Gear and Inventory

**Inventory:** Each player has **3 gear slots** plus their character's
permanent held item. Gear is found around the facility in lockers, desks,
crates, and on old bodies.

**Sharing:** Players can **drop** any item or **hand it directly** to a
nearby teammate (look at them and press the give button).

**Heavy items:** Some items are too heavy for normal players to carry while
running (car batteries, gas canisters). Other players move slowly with them;
the Guard carries them at normal speed.

| Gear | What it does | Notes |
|---|---|---|
| **Battery** | Recharges a flashlight | Flashlights slowly drain, so batteries are precious |
| **Fuse** | Fits into fuse boxes to power doors and machines | Engineer installs faster |
| **Keycard** | Opens doors of a matching security level (Green, Yellow, Red) | Deeper levels need higher cards |
| **Crowbar** | Pries open vents, crates, and jammed doors | Single-use pry takes 3 seconds and makes noise |
| **Flare** | Throw to light an area and distract monsters for 10 seconds | Great for covering teammates |
| **Med Kit** | Instantly revives a downed teammate from a distance of 1 meter | Rare |
| **Gas Mask** | Lets the wearer walk through toxic gas rooms | Filter lasts 45 seconds |
| **Walkie-Talkie** | Lets two players hear each other from anywhere. **Using it makes noise that attracts nearby monsters.** | Only 2 per chapter; very useful when split up. Press and hold to talk. Monsters hear transmissions. |
| **Reel Tape** | Plays a lore recording on tape machines | Collectible story item |
| **Car Battery** | Powers a single heavy machine | Heavy item |

---

## Weapons and Ammunition

**Weapon slots:** Each player has **1 weapon slot** (separate from 3 gear slots).
Weapons are rare — found in armories, on dead security, or hidden caches.

**Ammo scarcity:** Ammo is **very limited**. No ammo pickups refill full magazines.
Players must count every shot. Reloading is manual (eject mag, insert fresh).
No HUD ammo counter — check by inspecting the weapon (hold key to view mag).

**Noise discipline:** **All gunshots attract monsters** in a large radius.
Suppressed weapons reduce radius but are rarer. Melee is silent but risky.

**Sharing:** Weapons and magazines can be dropped/handed like gear.
Magazines are **not universal** — each weapon takes specific mags.

| Weapon | Role | Ammo Type | Capacity | Notes |
|---|---|---|---|---|
| **.38 Revolver** | Sidearm | .38 Speedloader | 6 | Common. Loud. Reload one round at a time (slow). |
| **9mm Pistol** | Sidearm | 9mm Mag | 15 | Semi-auto. Faster reload. Moderate noise. |
| **Suppressed 9mm** | Stealth sidearm | 9mm Mag | 12 | Quiet shot (short monster hearing range). Rare. |
| **12ga Pump Shotgun** | Close-quarters | 12ga Shell (loose) | 6 | Devastating close range. Manual pump. Loud. Shells loaded one by one. |
| **SMG (MP5-style)** | Volume of fire | 9mm Mag (extended) | 30 | Full auto. Burns ammo fast. Loud. Extended mags rare. |
| **Bolt-Action Rifle** | Long range | .308 Stripper Clip | 5 | High damage, penetrates armor. Slow cycle. Very loud. |
| **Tranquilizer Gun** | Non-lethal | Dart | 1 | Stuns monster 5s. Single shot. Silent. Extremely rare. |
| **Flare Gun** | Distraction / signal | Flare Shell | 1 | Fires flare far. Lights area, draws monsters to impact. Loud. |

**Melee (always available, no slot):**
- **Combat Knife** — Quick, weak. Good for cutting cords, not fighting.
- **Crowbar** (if in gear slot) — Heavy swing, stuns briefly. Loud impact.
- **Guard's Flashlight** — Heavy blunt. Only Guard has it.

**Character weapon affinities (what each is most likely to grab first):**
- **Son:** .38 Revolver (light, fits tracker role)
- **Journalist:** Suppressed 9mm (stealth, lore focus)
- **Engineer:** 12ga Shotgun (breach doors, close defense)
- **Guard:** 9mm Pistol + Flashlight melee (sustained defense)

Nobody *starts* with these; they are the weapons each character is built to use
best once the team finds them. Chapter 1's armory (deep in the tunnels, off the maintenance bypass) is
where the team gets its first guns.

**Ammo pickup examples per chapter:**
- Ch 1: ~12 .38 rounds, 15 9mm, 6 shells total (shared across team)
- Ch 2: Adds 30 SMG rounds, 5 .308
- Ch 3: Adds Tranq dart, Flare shells
- Ch 4–6: Very rare top-ups; mostly scavenged from fallen

---

## Puzzle Types

Build these as reusable puzzle pieces so they can be mixed across chapters.
Every puzzle below requires teamwork.

| Puzzle | How it works | Teamwork needed |
|---|---|---|
| **Dual Key Console** | Two keys must be turned at the same time at consoles in different rooms (like a Cold War missile launch) | Timing and communication |
| **Split Code** | One player sees a code on a monitor; another must enter it on a keypad in a different room | One reads, one enters |
| **Power Routing** | The Engineer repairs a generator while others find fuses and the Guard holds back monsters | All roles at once |
| **Weighted Plates** | Heavy plates hold doors open only while weighed down by a player or a heavy object | Someone stays behind |
| **Vent Crawl** | One player crawls through a narrow vent to unlock a door from the other side | Others defend the doorway |
| **Darkroom Photos** | The Journalist develops photos in a darkroom to reveal a hidden clue (like a safe combination) | Others protect her while she works |
| **Radio Frequency** | One player tunes an old radio while another reads the correct frequency from a chart elsewhere | Communication |
| **Morse Code** | A signal light blinks a message; one player reads it and another uses a translation sheet | Communication |
| **Gas Room** | A player in a gas mask walks through toxic rooms while a teammate at a map guides them over walkie-talkie. **Using the walkie-talkie attracts monsters.** | Guidance, noise discipline |
| **Hunted Hallway** | The Son senses where the monster is and guides teammates carrying heavy items past it. **The Long Man scrambles Sense** — teammates must rely on sound and callouts. | Tracking and trust |

---

## Chapters

| # | Name | Spotlight | Goal | Ending |
|---|---|---|---|---|
| 1 | The Surface | Journalist | Break into the weather station, find the hidden elevator, learn the controls | First monster appears; elevator cable snaps, trapping the team below |
| 2 | Power Station | Engineer | Restore three generators to power the facility | Clues reveal the Engineer helped build the experiment machines |
| 3 | The Holding Cells | Guard | Reach the sealed lower levels | The truth about the night Frank sealed the doors |
| 4 | The Deep Labs | Son | Navigate the experimental wings | Son unlocks **Resonance** — sees monster weak points |
| 5 | The Reactor Core | Engineer | Overload the facility's heart to escape | Conduit reveals its origin; Engineer's past choice |
| 6 | Subject Zero | Son | Confront the source in the deepest vault | Son unlocks **Inheritance** — final choice determines ending |

**Build Chapter 1 fully before starting Chapter 2.**

---

## The Son's Evolving Powers

The Son (Eli) starts with only **Sense**. As the story progresses, he unlocks
new abilities tied to his parent's legacy and the IRONWOOD experiments.
Each power has a cooldown and makes noise (except Sense).

| Chapter | Power | Description | Cooldown | Noise |
|---|---|---|---|---|
| 1 (start) | **Sense** | Hold to see nearby monsters glow through walls for 3s | 20s | Silent |
| 2 | **Pulse** | Tap to send a sonar ping — reveals all monsters' exact positions and movement direction in a 30m radius for 2s | 30s | Loud — attracts monsters to ping origin |
| 3 | **Resonance** | Hold on a monster to highlight its weak point (glowing organ/implant) for teammates. Increases team damage to that target by 50% for 5s | 40s | Moderate — monster hears it |
| 4 | **Echo Walk** | Briefly phase into "echo space" (2s): move silently, pass through monster collisions, see recent monster paths as trails. Cannot interact. | 45s | Silent activation; loud exit |
| 5 | **Inheritance** | Channel parent's IRONWOOD serum (10s): gain temporary **monster traits** — Sense always on, move silently, monsters hesitate to attack you. Ends in exhaustion (slowed, no abilities 30s). | Once per chapter | Very loud — all monsters drawn to you |

**Teamwork design:** Each new power changes how the team plays:
- **Pulse** — Son becomes a radar; team coordinates pushes during ping windows
- **Resonance** — Son marks priority targets; Engineer/Guard focus fire
- **Echo Walk** — Son scouts ahead solo, returns to guide team through patrol routes
- **Inheritance** — Son becomes a decoy/tank for final confrontation; team completes objective while monsters fixate on him

**Narrative tie:** Each power unlocks at a personal lore moment (finding parent's
recordings, injection sites, serum vials). The Journalist photographs these
for the journal. The final choice in Chapter 6 uses Inheritance.

---

## Chapter 1 Lore and Experiments

**The facility:** Site 12, hidden under the "Blackwater Weather Station."
**The program:** Project IRONWOOD, a 1960s government program to create
stronger, tougher soldiers. Volunteers were told it was vitamin research.

### Personal experiment threads

In Chapter 1, each character discovers one experiment connected to their own
past. This introduces every character's story and teases their spotlight chapter.

**Personal items rule (teamwork):** Any player can find a personal item, but it
only fully "unlocks" when its owner picks it up or looks at it. The owner then
says a short voice line and the full lore entry appears in everyone's journal.
Other players see a hint like *"This belongs to the Son."* so they must bring
their teammate to it.

| Character | Experiment they discover | What they learn | Teases |
|---|---|---|---|
| **Journalist** | **Serum H-7 "Growth"** — the experiment that created Subject 7, the Long Man | Her missing informant worked here and was trying to expose H-7 before he vanished | Chapter 1 main story |
| **Engineer** | **The Growth Chamber** — the machine that delivered H-7 | He designed it. His signature is on the blueprint | Chapter 2 |
| **Guard** | **The Level B Containment Order** | His name is on the order to seal the lower levels "regardless of personnel inside" | Chapter 3 |
| **Son** | **The IRONWOOD Volunteer Program** | His parent was Volunteer 14, and was moved to a secret "Program Zero" | Chapter 4 |

### Subject 7 — "The Long Man" (Chapter 1 monster)

A young soldier who volunteered for Serum H-7. It was meant to make bones
stronger. Instead, his bones never stopped growing. His medical files show his
height climbing week after week until staff note that he "no longer fits in
his cell." He was moved to the maintenance tunnels, which is where the team
meets him. He is sensitive to light (weak to the Journalist's flash).

### Lore placement, room by room

Types of lore: **Files** (folders and papers), **Reel Tapes** (audio logs
played on tape machines), **Photos** (taken by the Journalist), **Posters**,
**Environmental clues** (things written on walls or left behind), and
**Personal Items** (tied to one character). Items marked **Required** are
needed to finish the chapter; everything else is optional to find.

**Room 1 — Weather Station Exterior**
- **Environmental:** Rusted sign, "Property of U.S. Government — No Trespassing"
- **Personal Item (Journalist):** Her informant's abandoned car. Inside is his
  notebook with the words "H-7" and "they're still down there" circled
- **Photo:** Journalist can photograph fresh drag marks leading to the station,
  proving something still moves around here

**Room 2 — Station Office**
- **File:** Staff directory. One name is scratched out (the Engineer's)
- **Personal Item (Engineer):** His old desk nameplate and coffee mug, still
  sitting where he left them
- **Environmental:** A corkboard with the Journalist's own newspaper articles
  pinned to it. Someone was watching her
- **Reel Tape 1 (Required):** The facility director welcoming new "volunteers"
  and promising them they'll serve their country. The keypad code for the
  Split Code puzzle is mentioned at the end

**Room 3 — Hidden Stairwell**
- **Poster:** "STRONGER SOLDIERS. SAFER NATION." with a smiling soldier
- **Personal Item (Guard):** A dusty clipboard with the guard duty roster for
  the night of the sealing. Frank's name is on it
- **Environmental:** Tally marks scratched into the wall, hundreds of them

**Room 4 — Maintenance Tunnels**
- **File:** Subject 7 medical log, showing his height growing each week
- **Environmental:** A height chart painted on the wall with marks climbing
  higher and higher until they go past the ceiling
- **Personal Item (Son):** His parent's volunteer ID card: "Volunteer 14,"
  stamped *TRANSFERRED — PROGRAM ZERO*
- **Personal Item (Son):** A crayon drawing he made as a child and mailed to
  his parent, taped to the inside of a locker
- **Photo:** Journalist photographs the Long Man. This photo is proof of the
  experiments and completes her Chapter 1 story

**Room 5 — Elevator Room**
- **Personal Item (Engineer):** The Growth Chamber blueprint with his signature
- **File (Required):** Level B Containment Order, signed and stamped, with
  Frank listed as the guard responsible. Needed to learn the elevator override
- **Reel Tape 2:** A panicked scientist's final recording as the alarms go off
  and the doors begin to seal
- **Environmental:** The elevator control panel shows "LEVEL B — SEALED BY
  ORDER" as the team rides down, right before the cable snaps

### Lore tasks for Claude Code
- [x] Lore item data format (title, type, text or audio, owner character if personal)
- [x] Journal menu with tabs: Files, Tapes, Photos, Personal
- [x] Personal item system with owner voice lines and hints for other players
- [x] Tape machine interactable that plays Reel Tapes out loud for everyone nearby
- [x] Journalist photo system that recognizes photographable lore targets
- [x] Place all Chapter 1 lore items listed above (placeholder text is fine at first)

---

## Project Folder Structure

```
res://
├── scenes/
│   ├── main_menu/
│   ├── lobby/
│   ├── player/
│   ├── monsters/
│   ├── interactables/
│   └── chapters/
│       └── chapter_1/
├── scripts/
│   ├── autoload/        # global scripts (NetworkManager, GameState)
│   ├── player/
│   ├── abilities/
│   ├── monsters/
│   └── interactables/
├── assets/
│   ├── models/
│   ├── textures/
│   ├── audio/
│   └── ui/
└── ui/
```

---

## Build Phases

### Phase 1 — Project Setup
- [x] Create the Godot project and folder structure above
- [x] Set up Git with a Godot `.gitignore`
- [x] Create a simple gray-box test room (floor, walls, a few boxes)
- [x] Set up input actions: move (WASD), look (mouse), sprint (Shift),
      crouch (Ctrl), interact (E), ability (Q), flashlight (F)

### Phase 2 — Single-Player First-Person Controller
- [x] First-person camera with mouse look
- [x] Walking, sprinting with stamina, crouching
- [x] Head bob and footstep sounds (placeholder sounds are fine)
- [x] Flashlight toggle with a narrow cone of light
- [x] Interaction system: look at an object, press E, it responds
- [x] Test: walk around the test room with the flashlight

### Phase 3 — Multiplayer Foundation
- [x] `NetworkManager` autoload: host a game, join by IP, handle disconnects
- [x] Simple main menu: Host, Join (IP box), Quit
- [x] Spawn a player for each person who joins (up to 4)
- [x] Sync player movement, camera direction, and flashlight on/off
- [x] Each player only controls their own character
- [x] Test: run two copies of the game on one computer and see both players move

### Phase 4 — Lobby and Character Select
- [x] Lobby screen listing connected players
- [x] Character select: each of the four characters can only be picked once
- [x] Host presses Start when everyone has picked
- [x] Each character shows their held item in first-person view (placeholder shapes)

### Phase 5 — Character Abilities
- [x] Base ability script with cooldown handling (shared by all four)
- [x] Son: Sense (monsters glow through walls)
- [x] Journalist: Camera Flash (stun) and photographing evidence
- [x] Engineer: Repair (hold to fix/hack objects with a progress bar)
- [x] Guard: hold doors, push heavy objects, carry downed players
- [x] All abilities work correctly in multiplayer
- [x] Test: each ability with 2+ players

### Phase 6 — Monster AI
- [x] One test monster using NavigationAgent3D
- [x] States: Patrol → Hear/See player → Chase → Search → Patrol
- [x] Hearing: reacts to sprinting and the Guard's loud movement
- [x] Sight: reacts to players in its view cone, especially flashlights
- [x] Catching a player makes them "downed"
- [x] Reacts to Journalist's stun and Guard-held doors
- [x] Monster runs on the host and syncs to other players
- [x] Test: the monster chases the right player and loses them when hidden

### Phase 7 — Gear and Inventory
- [x] Item pickup system (look at item, press E, it goes into a free slot)
- [x] 3-slot inventory with a simple hotbar UI; scroll or 1–3 to switch items
- [x] Drop item and give item to a nearby teammate
- [x] Heavy items that slow the carrier (except the Guard)
- [x] Flashlight battery drain and recharging with Batteries
- [x] Build each gear item from the Gear table, one at a time, testing each
- [x] All pickups, drops, and handoffs sync correctly in multiplayer
- [x] Test: two players pass items back and forth without duplicates or losses

### Phase 8 — Co-op Puzzle Pieces
- [x] Reusable puzzle building blocks: button, lever, keypad, key console,
      pressure plate, fuse box, locked door, vent, radio, signal light
- [x] Build each puzzle type from the Puzzle Types table in the test room
- [x] Every puzzle's state is controlled by the host and synced to all players
- [x] Backup solutions for when a character is missing (e.g. no Engineer:
      a slower manual crank opens the door)
- [x] Test: every puzzle with 2 players, and confirm none can be solved solo

### Phase 9 — Core Game Systems
- [x] Downed and revive system (30 second timer)
- [x] Checkpoints and restart when the whole team is downed
- [x] Collectible lore: notes, reel tapes, and photos with a journal menu
- [x] Ping system: press a button to mark an item or spot for teammates
- [x] Pause menu and settings (volume, mouse sensitivity, brightness)
- [ ] **Proximity voice chat:** players within 5 meters hear each other
- [ ] **Walkie-talkie system:** paired players talk at any distance; holding
      talk button emits sound radius that attracts monsters (host syncs
      monster investigation target)
- [x] **Weapons and ammo:** one weapon slot per player (separate from gear),
      ammo scarcity, gunshots attract monsters, weapons/ammo can be shared
- [x] **No starting weapons:** every chapter begins unarmed; weapons are looted
      from the world. A weapon can be dropped (H) or handed over, and you lose
      it if you go down.
- [x] **Monsters take damage** from gunfire and are driven off (never killed),
      so a chase can always come back later

### Phase 10 — Chapter 1: "The Surface"

Room-by-room plan (gray-box first):

1. **Weather Station Exterior** — Locked gate. The Guard lifts it while others
   slip under, then someone finds a crowbar to jam it open for him.
   *Gear: Crowbar, Battery.*
2. **Station Office** — A **Split Code** puzzle: the office computer shows a
   code, the keypad is down the hall. Hidden stairwell behind a filing cabinet
   (Guard pushes it). *Gear: Green Keycard, Walkie-Talkie, first Reel Tape.*
3. **Hidden Stairwell** — Dark and narrow. Flashlights start draining here, so
   players learn to share batteries. *Gear: Batteries, Flare.*
4. **Security Armory (bottom of the stairwell)** — The players arrive **unarmed**.
   The Long Man is waiting in the dark and charges them the moment they reach
   the bottom. They scramble to the weapon racks: grab a gun and drive him off
   with fire. This ambusher **flees for good** once beaten (the real one still
   waits in his cell). *Gear: the team's first weapons — Shotgun, Pistol,
   Revolver, Suppressed 9mm — plus ammo and a Med Kit.*
5. **Maintenance Tunnels** — A **Vent Crawl** to unlock a door from the other
   side, then the **Long Man encounter**: a chase where the **Long Man
   scrambles the Son's Sense** (false echoes), the Journalist's flash stuns it,
   and the Guard holds a door shut behind the team. Players learn to
   communicate monster positions verbally when Sense fails.
   *Gear: Fuse, Med Kit.*
6. **Elevator Room** — **Power Routing**: the Engineer repairs the elevator
   generator, others find two missing fuses, and the Guard holds off the
   monster. Then a **Dual Key Console** starts the elevator.

Tasks:
- [x] Gray-box all five rooms
- [x] Place puzzles and gear as listed above
- [x] Confirm every character's ability is needed at least once
- [x] **Unarmed start + armory:** players begin with no weapons and arm up from
      the armory racks, deep in the tunnels off the maintenance bypass
- [x] One chase sequence through narrow tunnels
- [x] Lore items that introduce the facility and each character's reason for coming
- [x] Ending: elevator ride down, cable snaps, screen goes black, "Chapter 1 Complete"
- [x] **Long Man scrambles Son's Sense** — false echoes, verbal callouts work
- [x] **Walkie-talkie attracts Long Man** — transmission noise radius, monster investigates
- [ ] **Proximity chat** — test 5m range, no monster attraction
- [ ] Replace placeholder art with real models, textures, and lighting
      (First pass done: generated PBR textures, forest, night sky, props,
      light fixtures, screen filter, new Long Man body. Still needs real
      character models like Eli's .glb.)
- [x] Horror atmosphere: flickering lights, fog, ambient sounds, music stingers

### Phase 11 — Polish and Playtesting
- [ ] Playtest with real friends and write down what's confusing or not scary
- [ ] Teamwork check: did players have to talk and help each other? If anyone
      could finish a section alone, redesign it
      (Automated check done: in a team game no Chapter 1 section can be
      finished by one player. Still needs real players for the "did they
      talk" part.)
- [x] Online co-op only: Start needs at least 2 players (solo mode removed)
- [x] Fix bugs, especially multiplayer sync problems
- [x] Balance ability cooldowns and monster speed (first pass; tune again after playtests, see PLAYTEST.md)
- [x] Export builds for Windows (export_presets.cfg; build lands in build/windows/)

### Unreal Engine 5 port (in `unreal/SubjectZero/`, see its README)
The Godot game stays the main version until the Unreal one catches up.
The level is shared: `tools/export_for_unreal.gd` writes Chapter 1 to
`unreal/SubjectZero/Content/Data/chapter1.json`, and Unreal builds it from that.
- [ ] U1: Level built from the export, Host/Join, walk/sprint/crouch, flashlight, doors (code written, needs its first build on a PC with Unreal)
- [ ] U2: Items + inventory, keycard door, lore notes and journal
- [ ] U3: Puzzles (hold switches, gate, keypad/monitor, vent, fuses, generator, launch keys, elevator ending)
- [ ] U4: The Long Man, downed / help up, checkpoints
- [ ] U5: The four characters and their abilities
- [ ] U6: Real materials and textures, sounds, polish

### Later (after Chapter 1 is fun)
- Steam lobbies and invites (GodotSteam)
- Chapters 2, 3, 4, 5, and 6
- Unique monster designs for each chapter
- Son's evolving powers (Pulse, Resonance, Echo Walk, Inheritance)

---

## Monster Ideas (to design later)

Each monster is designed to **counter one character's ability**, forcing the
team to adapt and protect that player.

- **Chapter 1 — The Long Man (counters Son's Sense)**
  A failed test subject stretched too tall for the tunnels, crawls on all fours.
  **Counter:** His mutated biology **scrambles the Son's Sense ability** — when
  the Son uses Sense near him, it shows false positives (ghost echoes) or
  nothing at all. The Son must rely on teammates' callouts instead.

- **Chapter 2 — The Conduit (counters Engineer's Repair)**
  Something fused with the facility's machinery, attracted to electricity.
  Restoring power wakes it up. **Counter:** It **sabotages repairs** — when the
  Engineer uses Repair, the Conduit can reverse progress remotely or overload
  the machine, stunning the Engineer. The team must guard the Engineer while
  they work, and kill power to slow the monster.

- **Chapter 3 — The Wardens (counters Guard's Strength)**
  The people Frank sealed in, now changed. They still knock on doors.
  **Counter:** They are **too strong for the Guard to hold back** — doors held
  by the Guard buckle faster, and heavy objects the Guard moves can be shoved
  aside. The Guard cannot simply brute-force; the team must use barricades,
  traps, and environmental hazards instead.

- **Chapter 4 — The Mimic (counters Journalist's Camera Flash)**
  A shapeshifter that copies team members' voices and appearances.
  **Counter:** It **feeds on light** — the Camera Flash doesn't stun it; it
  *empowers* it, making it faster and deadlier. The Journalist must use flares,
  environmental lights, or darkness. The Son's Sense works reliably — the team
  must track it without flash.

- **Chapter 5 — The Conduit Prime (counters Engineer's Repair / Son's Pulse)**
  The Conduit's original form, fused with the reactor core.
  **Counter:** It **absorbs energy** — Engineer's Repair speeds it up; Son's
  Pulse reveals *its* position to *it* (two-way ping). The Engineer must work
  unpowered; the Son must use Sense/Resonance instead of Pulse.

- **Chapter 6 — Subject Zero (counters Son's Inheritance / all abilities)**
  The original volunteer — the Son's parent, transformed.
  **Counter:** It **mirrors abilities** — Sense shows it as a teammate, Pulse
  hits the Son back, Resonance marks a teammate as weak point, Echo Walk
  pulls the Son out of phase, Inheritance triggers a shared health pool (damage
  to Subject Zero damages the Son). The team must defeat it *without* the Son
  using powers — the Son guides them verbally while suppressed.

---

## Definition of Done for Each Task

1. It works in the Godot editor with no errors.
2. It works with at least 2 players (for anything multiplayer).
3. I have tested it myself.
4. It is committed to Git.
