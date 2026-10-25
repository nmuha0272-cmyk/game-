# GAME_PLAN.md — Working Title: "Deepwell"

A first-person, chapter-based, 1–4 player co-op horror game set in an abandoned
Cold War research facility, set in 2015. This file is the master plan for building the game
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
The program started during the Cold War but secretly kept running until the
facility was sealed in 1999. Eli's parents both died there that night (the
official story was a gas leak).

**Why they go in (2015):** seven people have gone missing near the station
since August, including Eli's two best friends, **Marcus Bell** and **Jenna
Park**, who went in to find out what really happened to his parents. Four
people go in after them, led by **Cole Brennan**, the soldier who raised Eli
like a son after his parents died.

**Frozen in time:** The facility never upgraded its Cold War equipment, so
everything inside looks like the 1960s–70s (reel tapes, bulky computers,
bunker doors), while the four characters carry modern 2015 gear.
**No phones:** Cell phones get no signal underground, which is why the team
relies on walkie-talkies.

**Core loop:** Explore → find and share gear → solve co-op puzzles → survive
monster encounters → uncover story clues → descend to the next area.

---

## Game Style: Poppy Playtime + Resident Evil

Deepwell mixes the best parts of both games, split into six chapters.

**From Poppy Playtime:**
- Chapter-based story, each chapter one level deeper with its own monster
- Creepy "human but wrong" monsters with one big signature scare
- Environmental puzzles (power, doors, keys) and co-op puzzle rooms
- Scripted chase sequences through tight corridors
- Lore told through tapes, files, posters, and photos
- Each chapter gives players a new tool or upgrade

**From Resident Evil:**
- **Resource management:** limited ammo, healing, and batteries. Players must
  choose what to carry and what to leave
- **Combat as a last resort:** guns and melee weapons exist, but ammo is rare
  and monsters are tough, so running and hiding are often smarter
- **Safe rooms:** quiet rooms where monsters can't enter, with calm music,
  a save point, and a storage box
- **Item combining:** mix items to make better ones (see Crafting)
- **Key items and backtracking:** find a keycard or tool, then go back to
  open earlier locked doors and reach new areas
- **Interconnected maps:** each chapter's area loops back on itself with
  shortcuts that unlock as players explore
- **Map system:** an in-game map that fills in as players explore and marks
  locked doors and items they've seen
- **Boss fights:** each chapter ends with a big encounter against its monster,
  using the environment, puzzles, and teamwork, not just shooting

**The balance:** Chapters 1–2 lean more toward Poppy Playtime (run, hide,
puzzles, almost no weapons). From Chapter 3 on, more Resident Evil
elements appear (guns, ammo, crafting, bosses), and Chapters 5–6 feel most
like Resident Evil. Monsters can never be killed with normal weapons, only
stunned, so the horror stays.

**The heart of this game is TEAMWORK.** No player should be able to get
through the facility alone. Every system (abilities, gear, puzzles, monsters)
should push players to talk, split up, cover each other, and rely on each other.

**Tone:** Dark, tense, retro. Flickering fluorescent lights, bunker doors,
reel-to-reel tapes, propaganda posters, gas masks, bulky old computers.

---

## Names Reference

| Name | Who or what |
|---|---|
| **Eli Reyes** | The Son, age 21 |
| **Sgt. Daniel Reyes** | Eli's father, Volunteer 14. Officially died in the 1999 sealing; really Walter took him into Project ECHO, and he became **Echo** |
| **Dr. Maria Reyes** | Eli's mother, a Deepwell doctor. Murdered by Walter in 1999 when she tried to get the volunteers out; her last message is on a reel tape in Chapter 1 |
| **Marcus Bell** | Eli's best friend, 21, engineering student. Missing. Found alive in Chapter 4, then playable (see "The Walter twist") |
| **Jenna Park** | Eli's best friend, 20. Missing with Marcus |
| **The Missing Seven** | Daniel Marsh (Nora's source), Ruth Alvarez, Tomas Greer, Kelly Ann Doss, Owen Pratt, Marcus Bell, Jenna Park |
| **Nora Vance** | The Journalist, age 35 |
| **Walter Kessler** | The Engineer, age 60. **Secretly the main villain** (revealed halfway through Chapter 4): he started Project ECHO, designed the Goliath Chamber, killed Eli's parents in 1999, and has kept the experiments going ever since |
| **Cole Brennan** | The Guard, age 36. Sealed Level B in 1999 at age 20, then **took 5-year-old Eli in and raised him like his own son**. They have a father-and-son relationship (Eli doesn't know Cole sealed his dad inside) |
| **Sentry** | A German Shepherd from Deepwell's K-9 unit, given the Goliath Serum in 1999: now horse-sized. Daniel Reyes used to feed him. Joins Eli in Chapter 2 as a companion Eli commands (see [Chapter 2 plan](docs/CHAPTER2_PLAN.md)) |
| **Deepwell** | The secret facility under the Blackwater Weather Station |
| **Project BASTION** | The Cold War super-soldier program (1960s–1991) |
| **Project ECHO** | Walter's secret branch of the program. Officially ended in 1999; Walter never stopped it |
| **The Goliath Serum (G-7)** | The serum meant to create giant soldiers |
| **Goliath** | Subject 7, nicknamed after the serum that changed him (Ch. 1 monster) |
| **Conduit** | Test subject fused with the facility's wiring (Ch. 2 monster) |
| **The Sealed** | The blind subjects Cole locked in Level B (Ch. 3 monsters) |
| **Echo** | The final result of Project ECHO, once Sgt. Daniel Reyes; copies voices (Ch. 4 and 6) |
| **Dr. Harold Ashby** | Original director of Deepwell; his voice is on the welcome tape |
| **Dr. Lillian Ashby** | His daughter, who pays for Walter's program (Ch. 5–6) |
| **The Warden** | Walter's newest, successful modern super-soldier (Ch. 5–6 monster) |

---

## Main Menu: The Deepwell Home Screen

The game opens on a car driving down a dark forest road at night, on the way
to the Blackwater Weather Station. Files: `scenes/main_menu/deepwell/`
(`main_menu_car.tscn` is the home screen, `main_menu.tscn` the title and
buttons on top of it). `scripts/main.gd` opens it when the game starts.

**Flow:**
1. **Title:** DEEPWELL, with Host Game, Join Game, Settings, Credits, Quit.
2. **Host or Join:** the camera moves into the back seat. (Join first asks
   for the host's IP and waits until it connects.)
3. **Pick a character in the car:** Eli drives, Cole sits next to him, Nora
   and Walter are in the back. Hover a name card or a person: the camera
   glides to them and shows their role, story and abilities. Click, then
   **PLAY AS ...**. Seats other players already took show **TAKEN**.
   - Eli = The Son, Cole = The Guard, Nora = The Journalist, Walter = The Engineer
4. **The drive:** the camera moves behind the car, it drives up to the
   station gate, stops, and fades to black (Enter or Esc skips it).
5. **Lobby:** everyone is listed with their character; the host presses
   **Start Game**, then the opening cutscene and Chapter 1 begin.

**Rules:**
- Host/Join/character picks go through the game's own `NetworkManager` and
  `GameState` (the host decides), so every player's screen agrees.
- Settings opens the game's own Settings menu (one settings file).
- Leaving a game or losing the connection returns to the home screen.
- Real character models can sit in the seats later (see the README in that
  folder); until then they are simple stand-in shapes.

---

## Characters

Every player picks one character. Each character can only be picked once per
game. Each has one unique ability, so the team must work together.

| Character | Role | Ability | Held Item (first-person view) |
|---|---|---|---|
| **Eli Reyes** (The Son) | Tracker | **Sense:** Hold a button to see nearby monsters glow through walls for 3 seconds, and all his teammates wherever they are (blue, or red if they're down). Only Eli sees it. 20 second cooldown. | Parent's dog tags |
| **Nora Vance** (The Journalist) | Stunner / Lore | **Camera Flash:** Stuns a monster in front of her for 2 seconds. 15 second cooldown. Photographing evidence unlocks lore entries. | Digital camera with external flash |
| **Walter Kessler** (The Engineer) | Fixer | **Repair:** Hold to fix generators, elevators, broken panels, and hack locked security doors. Only he can do this. | Wrench |
| **Cole Brennan** (The Guard) | Protector | **Strength:** Hold doors shut against monsters, move heavy objects, build barricades, carry a downed teammate. Moves slower and makes more noise. | Heavy flashlight |

**Shared by all characters:** walk, sprint (limited stamina), crouch, flashlight,
interact, pick up small items, revive downed teammates.

**Downed system:** A player caught by a monster is "downed," not killed. A
teammate can revive them within 30 seconds. If everyone is downed, restart
from the last checkpoint.

---

## Teamwork Design Rules

Every level, puzzle, and encounter must follow these rules:

1. **No solo solutions.** Every puzzle needs at least 2 players to solve.
2. **Everyone matters.** Each chapter must have moments where each of the four
   abilities is needed. If a character is missing (fewer than 4 players),
   provide a slower backup solution so the game is still beatable.
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

**Inventory (as built):** each player has **4 quick slots** (keys 1–4 / mouse
wheel, what's in your hand) plus **storage** (2 slots to start). **E** opens
the inventory menu: click an item, then a quick slot, to swap them. A **Field
Pouch** (+1) and a **Backpack** (+2) add storage, up to 10. Gear is found in
lockers, desks, crates and on old bodies.
- **Weapons are items too:** pick a gun up into a slot, select it and press
  **4** to draw it, left-click to fire, **R** to reload, **H** to drop it.
  Going down drops the gun you were holding.
- **Ammo:** using an ammo box adds its rounds to a carried gun that takes
  that ammo (the gun keeps its own spare ammo).

**Storage box:** Every safe room has a storage box. Items put in one box can
be taken out of any other box, and the whole team shares it.

### Crafting (combine items)

| Combine | Makes | Effect |
|---|---|---|
| Bandage + Antiseptic | **Med Kit** | Revives a downed teammate faster, or heals fully |
| Gunpowder + Empty Shells | **Ammo** | A few rounds for the gun the player chose |
| Battery + Battery | **Charged Battery** | Fully recharges a flashlight |
| Duct Tape + Pipe | **Reinforced Pipe** | Melee weapon that lasts twice as long |
| Alarm Clock + Battery | **Sound Lure** | Throwable noise distraction |
| Cloth + Alcohol + Lighter | **Fire Bottle** | Creates a wall of fire monsters won't cross for 8 seconds |

### Health

Players can take **2 hits**. The first hit leaves them **injured** (slower,
heavy breathing, screen edges red). The second hit makes them **downed**.
Med kits and bandages heal injuries. This works with the downed/revive system.

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
| **Walkie-Talkie** | Lets two players hear each other from anywhere | Only 2 per chapter; very useful when split up |
| **Reel Tape** | Plays a lore recording on tape machines | Collectible story item |
| **Car Battery** | Powers a single heavy machine | Heavy item |

---

## Voice Chat and Voice Detection (signature feature)

**The idea:** Players talk using in-game proximity voice chat, and **the
monsters can hear them.** Teamwork depends on communication, but every word
is a risk. Players must decide when it's safe to talk, whisper, or stay silent.

### How it works
- **Proximity voice:** Players hear teammates only when nearby. Voices get
  quieter with distance and are muffled through walls and doors.
- **Mic loudness = noise:** The game measures how loud each player's
  microphone is. Louder talking creates a bigger "noise circle" that monsters
  can hear.
  - Whisper: about 3 meters
  - Normal talking: about 10 meters
  - Yelling or screaming: about 25 meters
- **Monsters track the sound:** A monster that hears a voice walks to where
  the sound came from. Repeated noise turns a search into a chase.
- **Walkie-talkie danger:** Talking into a walkie-talkie lets a far-away
  teammate hear you, but your voice also plays out of **their** walkie's
  speaker, so a monster near them can hear it too.
- **Noise meter:** A small on-screen icon shows how loud the player is
  right now, so they can learn to control their voice.

### Monsters and voice
- **Goliath (Ch. 1):** Hears voices normally. Teaches players the rule.
- **Conduit (Ch. 2):** Hears walkie-talkie signals from much farther away.
- **The Sealed (Ch. 3):** Blind, so they hunt **only** by sound. Their
  hearing range is doubled. Total silence is the only safe option.
- **Echo (Ch. 4 and 6):** Hears everything and (stretch goal) copies short
  phrases players have said to lure them away.
- **The Warden (Ch. 5–6):** Smart and trained. Wears a modern headset that
  picks up walkie-talkie chatter, and he remembers where he last heard players.

### Fairness and settings
- **Players without a mic** can use a quick-chat wheel ("Over here!",
  "Monster!", "Help!") and pings. Quick-chat lines also make noise.
- **Push-to-talk** option, plus an open-mic option for braver players.
- **Mic sensitivity slider** so background noise in a player's room doesn't
  constantly alert monsters, plus a "voice detection" difficulty setting.
- **Privacy:** Voice audio is only sent to teammates in the same game and is
  never saved, unless the Echo mimic feature is turned on, which must
  be clearly explained and can be switched off in settings.

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
| **Gas Room** | A player in a gas mask walks through toxic rooms while a teammate at a map guides them over walkie-talkie | Guidance |
| **Hunted Hallway** | The Son senses where the monster is and guides teammates carrying heavy items past it | Tracking and trust |

---

## Chapters

| # | Name | Spotlight | Monster | Goal | Ending |
|---|---|---|---|---|---|
| 1 | The Surface | Nora | Goliath | Break into the weather station, find the hidden elevator, learn the controls | Elevator cable snaps, trapping the team below |
| 2 | Power Station | Walter | Conduit | Restore three generators to power the facility | Clues reveal Walter built the Goliath Chamber |
| 3 | Level B | Cole | The Sealed | Get through the sealed holding cells in total silence | The truth about the night Cole sealed the doors |
| 4 | Project ECHO | Eli | Echo (first appearance) | Find Eli's father's cell and the ECHO lab. **Halfway through: Walter is revealed as the main villain** and leaves the team; soon after, they find Marcus alive | Eli realizes Echo **is** his father. Echo escapes deeper into Deepwell |
| 5 | Still Running | Whole team (with Marcus) | The Warden | Discover a hidden modern lab under the old one | The experiments never stopped. Walter restarted them (with Lillian Ashby's money) and lured the Missing Seven here as new test subjects |
| 6 | The Way Out | Whole team (with Marcus) | The Warden and Echo | Escape as Walter floods Deepwell to erase the evidence | Eli must choose to free his father or end him, and the team only escapes if everyone works together |

### The Walter twist and the character switch

**The truth about Walter:** Walter Kessler started Project ECHO in the 1990s
and designed the Goliath Chamber. In 1999 Eli's mother, Dr. Maria Reyes,
tried to get the volunteers out, so Walter killed her and made it look like
the "gas leak". He took Eli's father, Sgt. Daniel Reyes (Volunteer 14), into
Project ECHO, and Daniel slowly became **Echo**. Officially both parents
died that night. Walter has been alive and running the experiments in
secret ever since, and in 2015 he lured the Missing Seven (Marcus and Jenna
too) to Deepwell as new test subjects. He joined the team to bring them
down deeper.

- **Chapters 1–3:** Walter is a normal playable character. Small clues hint
  at him (he knows the way in, he "used to work here", he built the Goliath
  Chamber, Maria's tape says someone locked Medical from the outside).
- **Halfway through Chapter 4:** the team finds the proof (Walter's own
  ECHO logs, and what he did to Eli's parents). Walter turns on them in a
  cutscene and leaves; from now on he is the main villain (not playable).
- **The switch:** whoever was playing Walter watches (spectator camera)
  until the team finds **Marcus Bell** alive in a holding cell a little
  later in Chapter 4. That player then plays Marcus for the rest of the game.
- **Jenna:** still missing after Chapter 4 (her fate to decide for Ch. 5–6).

**Marcus Bell (The Tinkerer)**

| | |
|---|---|
| **Role** | Fixer / Trapper |
| **Repair** | Fixes generators, elevators, panels and security doors like Walter, so every Engineer puzzle still works. A bit slower (Walter 4s, Marcus 5s). |
| **His own ability: Jury-Rig** | Press Q to build a beeping **noise-maker** out of scrap and throw it. Monsters within 25 m chase the noise for 8 seconds, so the team can sneak past or get away. 45 second cooldown. The noise-maker breaks when a monster reaches it. |
| **Held item** | Taped-together multitool |
| **Personality** | Jokes when he's scared. Feels guilty that Jenna is still missing. |

**Build Chapter 1 fully before starting Chapter 2.**

---

## Chapter 1 Lore and Experiments

**The facility:** Deepwell, hidden under the "Blackwater Weather Station."
**The program:** Project BASTION, a government program started in the 1960s to
create stronger, tougher soldiers. Volunteers were told it was vitamin research.
It was officially shut down when the Cold War ended in 1991, but a secret
branch called Project ECHO kept going until the facility was sealed in 1999.

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
| **Journalist** | **The Goliath Serum (G-7)** — the experiment that created Subject 7, Goliath | Her missing informant worked here and was trying to expose G-7 before he vanished | Chapter 1 main story |
| **Engineer** | **The Goliath Chamber** — the machine that delivered G-7 | He designed it. His signature is on the blueprint | Chapter 2 |
| **Guard** | **The Level B Containment Order** | His name is on the order to seal the lower levels "regardless of personnel inside" | Chapter 3 |
| **Son** | **The BASTION Volunteer Program** | His parent was Volunteer 14, and was moved to a secret "Project ECHO" | Chapter 4 |

### Subject 7 — "Goliath" (Chapter 1 monster)

A young soldier who volunteered for the Goliath Serum. It was meant to make bones
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
  notebook with the words "G-7" and "they're still down there" circled
- **Photo:** Journalist can photograph fresh drag marks leading to the station,
  proving something still moves around here

**Room 2 — Station Office**
- **File:** Staff directory. One name is scratched out (the Engineer's)
- **Personal Item (Engineer):** His old desk nameplate and coffee mug, still
  sitting where he left them
- **Environmental:** A corkboard with the Journalist's own newspaper articles
  pinned to it, some dated 2014. Someone has been here recently, and they've
  been watching her
- **Reel Tape 1 (Required):** The facility director welcoming new "volunteers"
  and promising them they'll serve their country. The keypad code for the
  Split Code puzzle is mentioned at the end

**Room 3 — Hidden Stairwell**
- **Poster:** "STRONGER SOLDIERS. SAFER NATION." with a smiling soldier
- **Personal Item (Guard):** A dusty clipboard with the guard duty roster for
  the night of the sealing. Cole's name is on it
- **Environmental:** Tally marks scratched into the wall, hundreds of them

**Room 4 — Maintenance Tunnels**
- **File:** Subject 7 medical log, showing his height growing each week
- **Environmental:** A height chart painted on the wall with marks climbing
  higher and higher until they go past the ceiling
- **Personal Item (Son):** His parent's volunteer ID card: "Volunteer 14,"
  stamped *TRANSFERRED — PROJECT ECHO*
- **Personal Item (Son):** A crayon drawing he made as a child and mailed to
  his parent, taped to the inside of a locker
- **Photo:** Journalist photographs Goliath. This photo is proof of the
  experiments and completes her Chapter 1 story

**Room 5 — Elevator Room**
- **Personal Item (Engineer):** The Goliath Chamber blueprint with his signature
- **File (Required):** Level B Containment Order, signed and stamped, with
  Cole listed as the guard responsible. Needed to learn the elevator override
- **Reel Tape 2:** A panicked scientist's final recording as the alarms go off
  and the doors begin to seal
- **Environmental:** The elevator control panel shows "LEVEL B — SEALED BY
  ORDER" as the team rides down, right before the cable snaps

### Lore tasks for Claude Code
- [ ] Lore item data format (title, type, text or audio, owner character if personal)
- [ ] Journal menu with tabs: Files, Tapes, Photos, Personal
- [ ] Personal item system with owner voice lines and hints for other players
- [ ] Tape machine interactable that plays Reel Tapes out loud for everyone nearby
- [ ] Journalist photo system that recognizes photographable lore targets
- [ ] Place all Chapter 1 lore items listed above (placeholder text is fine at first)

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
- [x] Set up input actions: move (WASD), look (mouse), sprint (Shift), crouch (Ctrl), interact (E), ability (Q), flashlight (F)

### Phase 2 — Single-Player First-Person Controller
- [x] First-person camera with mouse look
- [x] Walking, sprinting with stamina, crouching
- [x] Head bob and footstep sounds (placeholder sounds are fine)
- [x] Flashlight toggle with a narrow cone of light
- [x] Interaction system: look at an object, press E, it responds
- [x] Test: walk around the test room with the flashlight

### Phase 3 — Multiplayer Foundation
- [x] `NetworkManager` autoload: host a game, join by IP, handle disconnects
- [x] Main menu: the Deepwell home screen (Host, Join with IP box, Settings, Credits, Quit)
- [x] Spawn a player for each person who joins (up to 4)
- [x] Sync player movement, camera direction, and flashlight on/off
- [x] Each player only controls their own character
- [x] Test: run two copies of the game on one computer and see both players move

### Phase 4 — Lobby and Character Select
- [x] Lobby screen listing connected players
- [x] Character select in the Deepwell car: each of the four characters can only be picked once
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
- [x] One test monster using NavigationAgent3D (Long Man)
- [x] States: Patrol → Hear/See player → Chase → Search → Patrol
- [x] Hearing: reacts to "noise events" (sprinting, Guard's loud movement, dropped items, player voices) with position and range
- [x] Sight: reacts to players in its view cone, especially flashlights
- [x] Catching a player makes them "downed"
- [x] Reacts to Journalist's stun and Guard-held doors
- [x] Monster runs on the host and syncs to other players
- [x] Test: the monster chases the right player and loses them when hidden

### Phase 6.5 — Proximity Voice Chat and Voice Detection
- [x] Capture microphone audio (Godot AudioEffectCapture configured)
- [x] Send voice to other players and play it from that player's position in 3D
- [x] Distance fade and muffling through walls
- [x] Push-to-talk and open-mic options, plus mic sensitivity setting
- [x] Measure each player's mic loudness and send a noise event to monsters (whisper / talk / yell ranges)
- [x] On-screen noise meter
- [x] Quick-chat wheel for players without a mic
- [x] Test: talk near the monster and confirm it walks toward you; whisper and confirm it doesn't
- [x] Walkie-talkie voice (added in Phase 7 with the item) plays from the receiver's speaker and makes noise there

### Phase 7 — Gear and Inventory
- [x] Item pickup system (look at item, press E, it goes into a free slot)
- [x] 4-slot inventory with a simple hotbar UI; scroll or 1–3 to switch items
- [x] Drop item and give item to a nearby teammate
- [x] Heavy items that slow the carrier (except the Guard)
- [x] Flashlight battery drain and recharging with Batteries
- [x] Build each gear item from the Gear table, one at a time, testing each
- [x] All pickups, drops, and handoffs sync correctly in multiplayer
- [x] Test: two players pass items back and forth without duplicates or losses

### Phase 8 — Co-op Puzzle Pieces
- [x] Reusable puzzle building blocks: button, lever, keypad, key console, pressure plate, fuse box, locked door, vent, radio, signal light
- [x] Build each puzzle type from the Puzzle Types table in the test room
- [x] Every puzzle's state is controlled by the host and synced to all players
- [x] Backup solutions for when a character is missing (e.g. no Engineer: a slower manual crank opens the door)
- [x] Test: every puzzle with 2 players, and confirm none can be solved solo

### Phase 9 — Core Game Systems
- [x] Downed and revive system (30 second timer)
- [x] Checkpoints and restart when the whole team is downed
- [x] Collectible lore: notes, reel tapes, and photos with a journal menu
- [x] Ping system: press a button to mark an item or spot for teammates
- [x] Pause menu and settings (volume, mouse sensitivity, brightness)

**Built (core systems):**
- [x] **Progress is kept when the team dies:** doors that were opened stay open,
      unlocked doors stay unlocked, solved puzzles stay solved and cutscenes
      don't replay. The host remembers it (`GameState.level_progress`) and puts
      it all back after the level reloads at the checkpoint.
- [x] **Cutscenes** wait until every player has loaded, play once, and need
      Space **held** to skip (so jumping doesn't skip them).
- [x] **Settings:** volume, mouse sensitivity, brightness, **flashlight
      brightness** (each player picks their own), graphics, first/third
      person, voice chat options and rebindable controls.

### Phase 9.5 — Resident Evil Systems
- [x] Health: injured state and healing items
- [x] Safe rooms: monsters can't enter, calm music, save point
- [x] Shared storage box in every safe room
- [x] Crafting menu that combines two items using the Crafting table
- [x] Pouch upgrades that add inventory slots (up to 8, one per chapter in Ch. 2–5)
- [x] Map system that fills in as players explore and marks locked doors
- [x] Locked doors that need key items, plus shortcut doors that open from one side only
- [x] Melee weapons with durability
- [x] Firearms: aiming, recoil, reloading, jamming for old guns, very limited ammo, and gunshots as the loudest noise event (save until Chapter 3)
- [x] Boss fight framework: phases, arena triggers, and a reusable boss health/stun system (bosses are driven back or trapped, not killed)
- [x] Test: every system with 2+ players, especially shared storage

### Phase 10 — Chapter 1: "The Surface"
Room-by-room plan (gray-box first):

1. **Weather Station Exterior** — Locked gate. The Guard lifts it while others slip under, then someone finds a crowbar to jam it open for him. *Gear: Crowbar, Battery.*
2. **Station Office** — A **Split Code** puzzle: the office computer shows a code, the keypad is down the hall. Hidden stairwell behind a filing cabinet (Guard pushes it). *Gear: Green Keycard, Walkie-Talkie, first Reel Tape.*
3. **Hidden Stairwell** — Dark and narrow. Flashlights start draining here, so players learn to share batteries. *Gear: Batteries, Flare.*
4. **Maintenance Tunnels** — A **Vent Crawl** to unlock a door from the other side, then the **first monster encounter**: a chase where the Son senses it, the Journalist stuns it, and the Guard holds a door shut behind the team. *Gear: Fuse, Med Kit.*
5. **Elevator Room** — **Power Routing**: the Engineer repairs the elevator generator, others find two missing fuses, and the Guard holds off the monster. Then a **Dual Key Console** starts the elevator.

Tasks:
- [x] Gray-box all five rooms
- [x] Place puzzles and gear as listed above
- [x] Confirm every character's ability is needed at least once
- [x] One chase sequence through narrow tunnels
- [x] Lore items that introduce the facility and each character's reason for coming
- [x] Ending: elevator ride down, cable snaps, screen goes black, "Chapter 1 Complete"
- [x] Replace placeholder art with real models, textures, and lighting (car-based main menu + building model replacement ready)
- [x] Horror atmosphere: flickering lights, fog, ambient sounds, music stingers
- [x] **Arrival cutscene**: car stops at gate, characters exit and discuss options, loading dock entrance revealed (roll-up door jammed 60 cm, Cole lifts it), team enters building ground floor

**Chapter 1 as built** (in play order; the level is made by
`tools/make_chapter1.py`, so change the level there, not in the .tscn):

| # | Section | What you do |
|---|---|---|
| 1 | Exterior | Lift the gate (Cole), find the crowbar. A **MISSING poster** with the seven names is on the station's front wall |
| 2 | Front door power | Terminal (lights-out puzzle) + breaker by the front door: the station's lights come on |
| 3 | Office | Split code (computer + keypad), tape machine, safe, infirmary, push the filing cabinet to find the stairs |
| 4 | Hidden stairwell | Real steps, batteries drain from here. **Marcus and Jenna's camera** is on the landing (Eli's personal item) |
| 5 | Junction + Power Room | Fuel can on the landing → generator starts itself → set 3 breakers to the wiring diagram → the security shutter opens |
| 6 | Dorm Wing (required) | Throw the aux lever, set 5 breakers to the card in the bunk room |
| 7 | Maintenance bypass | The main tunnel caved in: a winding hallway with failing lights, puddles, dripping water, a supply room (hiding locker) and a shower room |
| 8 | Armory | Behind a door off the bypass: guns, ammo, the sign-out sheet. Everyone starts unarmed, so this is where the team arms up |
| 9 | Tunnels | Vent crawl, darkroom photo clue, flood → pump room drain code, the Long Man's cell and the **RUN!** chase |
| 10 | Elevator Room | Fuses, generator (Walter repairs), Containment Order, two consoles turned together |
| 11 | Boiler Room (optional) | Two relief valves in different rooms held at the same time → pressure cage of supplies |
| 12 | Morgue (optional) | Cold room code split over four toe tags (one is in the boiler room) |
| 13 | Observation Wing (optional) | One player stands on a plate to hold the booth open, another reads the vault code (changes every minute), someone enters it at the vault |
| 14 | Lab Wing | Airlock, lab power lever, Archive keypad (code read from the lab monitor), elevator key in the Archive |
| 15 | Comms Room (required) | Radio tuning: the live frequency is only on the antenna room chart, so one player reads, one tunes |
| 16 | Ending | The consoles need: power, the Containment Order, the elevator key, the Dorm aux power and the surface relay. Then the elevator drops and the cable snaps |

- [x] Extra Chapter 1 sections built: bypass, armory, Dorm Wing, Boiler Room, Morgue, Observation Wing, Comms Room
- [x] Every door opening and locker checked by an automatic test (no blocked doorways)

### Phase 11 — Polish and Playtesting
- [x] Playtest with real friends and write down what's confusing or not scary
- [x] Teamwork check: did players have to talk and help each other? If anyone could finish a section alone, redesign it
- [x] Fix bugs, especially multiplayer sync problems (all `find_item()` array indexing bugs fixed)
- [x] Balance ability cooldowns and monster speed (Eli 2x melee speed, Cole 1.5x melee speed in crafting)
- [x] Export builds for Windows
- [x] **Main menu integration**: car-based intro from `deepwell_main_menu(2).zip` with security camera, panel system, and arrival cutscene

### Later (after Chapter 1 is fun)
- Steam lobbies and invites (GodotSteam)
- Echo voice mimic (stretch goal)
- Chapters 2 through 6, each with: a safe room, a boss encounter, at least one shortcut loop, a pouch upgrade (Ch. 2–5), and new weapons or tools
- Weapon roadmap: Ch. 1–2 melee only, Ch. 3 the guard revolver, Ch. 4 shotgun, Ch. 5–6 modern guns from Walter's security
- Unique monster designs for each chapter
- **Eli-Cole relationship deepening**: Mother's death backstory, VIGIL connection, Cole/Eli special dialogue (dialogue cues implemented in arrival cutscene)

---

## Other Versions and Tools

- **Unreal Engine 5 version** (`unreal/SubjectZero/`): being ported phase by
  phase; see its README. Its Chapter 1 level comes from the Godot one:
  `godot --headless -s tools/export_for_unreal.gd` writes
  `Content/Data/chapter1.json`, and `scripts/export/unreal_export.gd` writes
  the items and weapons list (`items.json`). Not compiled yet: build errors go
  to Claude to fix.
- **Unity version** (`unity/Deepwell/`): being ported phase by phase like the
  Unreal one; see its README. Phase U1: Chapter 1 from the Godot level
  (`tools/export_for_unity.gd` writes the level model and data), walking,
  flashlight, doors. `scripts/export/unity_export.gd` writes the items list.
- **Roblox version** (`roblox/`): made by the `tools/roblox_*.py` scripts.
- **Animations:** `assets/animations/` holds the animation libraries
  (player, monsters, cutscenes, props). The player, the Long Man, the Wired,
  the opening cutscene and Eli's T-pose scene each have an AnimationPlayer
  using them. Real animations (for example from Mixamo) go into these files.
- **Models:** the team's own models are used exactly as made (never
  changed, shrunk or re-rigged); file names stay the same (for example
  Cole's model is still `frank.glb`).

---

## Monster Ideas (to design later)

- **Chapter 1:** A failed test subject stretched too tall for the tunnels,
  crawls on all fours in tight spaces.
- **Chapter 2:** Something fused with the facility's machinery, attracted to
  electricity. Restoring power wakes it up.
- **Chapter 3:** The people Cole sealed in, now changed. They still knock on doors.
- **Chapter 4:** Echo, who turns out to be Eli's father. Stalks the team
  rather than attacking right away.
- **Chapter 5:** The Warden, a modern super-soldier in tactical gear. Faster
  and smarter than the old experiments: opens doors, uses flashlights, and
  sets traps.
- **Chapter 6:** The Warden hunts the team during the escape while Echo
  appears at key moments. Whether Echo helps or attacks depends on
  Eli's choice.

---

## Definition of Done for Each Task

1. It works in the Godot editor with no errors.
2. It works with at least 2 players (for anything multiplayer).
3. I have tested it myself.
4. It is committed to Git.
