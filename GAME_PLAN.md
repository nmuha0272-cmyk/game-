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
facility was sealed in 1999. In **2015**, four people break in.

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
| **Sgt. Daniel Reyes** | Eli's father, Volunteer 14, taken into Project ECHO |
| **Nora Vance** | The Journalist, age 35 |
| **Walter Kessler** | The Engineer, age 60, designed the Goliath Chamber |
| **Cole Brennan** | The Guard, age 35, sealed Level B in 1999 at age 20 |
| **Deepwell** | The secret facility under the Blackwater Weather Station |
| **Project BASTION** | The Cold War super-soldier program (1960s–1991) |
| **Project ECHO** | The secret branch that kept running until 1999 |
| **The Goliath Serum (G-7)** | The serum meant to create giant soldiers |
| **Goliath** | Subject 7, nicknamed after the serum that changed him (Ch. 1 monster) |
| **Conduit** | Test subject fused with the facility's wiring (Ch. 2 monster) |
| **The Sealed** | The blind subjects Cole locked in Level B (Ch. 3 monsters) |
| **Echo** | The final result of Project ECHO, once Sgt. Daniel Reyes; copies voices (Ch. 4 and 6) |
| **Dr. Harold Ashby** | Original director of Deepwell; his voice is on the welcome tape |
| **Dr. Lillian Ashby** | His daughter, who secretly restarted the program in 2009 (main villain, Ch. 5–6) |
| **The Warden** | Ashby's newest, successful modern super-soldier (Ch. 5–6 monster) |

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
| **Eli Reyes** (The Son) | Tracker | **Sense:** Hold a button to see nearby monsters glow through walls for 3 seconds. 20 second cooldown. | Parent's dog tags |
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

**Inventory:** Each player starts with **4 gear slots** plus their
character's permanent held item. Gear is found around the facility in lockers,
desks, crates, and on old bodies. Like Resident Evil, players can find
**pouch upgrades** (one per chapter in Chapters 2–5) that add a slot, up to 8.
Key items (keycards, story items) don't take up slots.

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
| 4 | Project ECHO | Eli | Echo (first appearance) | Find Eli's father's cell and the ECHO lab | Eli realizes Echo **is** his father. Echo escapes deeper into Deepwell |
| 5 | Still Running | Whole team | The Warden | Discover a hidden modern lab under the old one | The experiments never stopped. Dr. Lillian Ashby has restarted them, and she's been watching Nora |
| 6 | The Way Out | Whole team | The Warden and Echo | Escape as Ashby floods Deepwell to erase the evidence | Eli must choose to free his father or end him, and the team only escapes if everyone works together |

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
- [ ] Create the Godot project and folder structure above
- [ ] Set up Git with a Godot `.gitignore`
- [ ] Create a simple gray-box test room (floor, walls, a few boxes)
- [ ] Set up input actions: move (WASD), look (mouse), sprint (Shift),
      crouch (Ctrl), interact (E), ability (Q), flashlight (F)

### Phase 2 — Single-Player First-Person Controller
- [ ] First-person camera with mouse look
- [ ] Walking, sprinting with stamina, crouching
- [ ] Head bob and footstep sounds (placeholder sounds are fine)
- [ ] Flashlight toggle with a narrow cone of light
- [ ] Interaction system: look at an object, press E, it responds
- [ ] Test: walk around the test room with the flashlight

### Phase 3 — Multiplayer Foundation
- [ ] `NetworkManager` autoload: host a game, join by IP, handle disconnects
- [x] Main menu: the Deepwell home screen (Host, Join with IP box, Settings, Credits, Quit)
- [ ] Spawn a player for each person who joins (up to 4)
- [ ] Sync player movement, camera direction, and flashlight on/off
- [ ] Each player only controls their own character
- [ ] Test: run two copies of the game on one computer and see both players move

### Phase 4 — Lobby and Character Select
- [ ] Lobby screen listing connected players
- [x] Character select in the Deepwell car: each of the four characters can only be picked once
- [ ] Host presses Start when everyone has picked
- [ ] Each character shows their held item in first-person view (placeholder shapes)

### Phase 5 — Character Abilities
- [ ] Base ability script with cooldown handling (shared by all four)
- [ ] Son: Sense (monsters glow through walls)
- [ ] Journalist: Camera Flash (stun) and photographing evidence
- [ ] Engineer: Repair (hold to fix/hack objects with a progress bar)
- [ ] Guard: hold doors, push heavy objects, carry downed players
- [ ] All abilities work correctly in multiplayer
- [ ] Test: each ability with 2+ players

### Phase 6 — Monster AI
- [ ] One test monster using NavigationAgent3D
- [ ] States: Patrol → Hear/See player → Chase → Search → Patrol
- [ ] Hearing: reacts to "noise events" (sprinting, the Guard's loud
      movement, dropped items, and later, player voices) with a position and range
- [ ] Sight: reacts to players in its view cone, especially flashlights
- [ ] Catching a player makes them "downed"
- [ ] Reacts to Journalist's stun and Guard-held doors
- [ ] Monster runs on the host and syncs to other players
- [ ] Test: the monster chases the right player and loses them when hidden

### Phase 6.5 — Proximity Voice Chat and Voice Detection
- [ ] Capture microphone audio (Godot AudioEffectCapture, or a voice plugin;
      research the best current option for Godot 4 first)
- [ ] Send voice to other players and play it from that player's position in 3D
- [ ] Distance fade and muffling through walls
- [ ] Push-to-talk and open-mic options, plus mic sensitivity setting
- [ ] Measure each player's mic loudness and send a noise event to monsters
      (whisper / talk / yell ranges)
- [ ] On-screen noise meter
- [ ] Quick-chat wheel for players without a mic
- [ ] Test: talk near the monster and confirm it walks toward you;
      whisper and confirm it doesn't
- [ ] Walkie-talkie voice (added in Phase 7 with the item) plays from the
      receiver's speaker and makes noise there

### Phase 7 — Gear and Inventory
- [ ] Item pickup system (look at item, press E, it goes into a free slot)
- [ ] 3-slot inventory with a simple hotbar UI; scroll or 1–3 to switch items
- [ ] Drop item and give item to a nearby teammate
- [ ] Heavy items that slow the carrier (except the Guard)
- [ ] Flashlight battery drain and recharging with Batteries
- [ ] Build each gear item from the Gear table, one at a time, testing each
- [ ] All pickups, drops, and handoffs sync correctly in multiplayer
- [ ] Test: two players pass items back and forth without duplicates or losses

### Phase 8 — Co-op Puzzle Pieces
- [ ] Reusable puzzle building blocks: button, lever, keypad, key console,
      pressure plate, fuse box, locked door, vent, radio, signal light
- [ ] Build each puzzle type from the Puzzle Types table in the test room
- [ ] Every puzzle's state is controlled by the host and synced to all players
- [ ] Backup solutions for when a character is missing (e.g. no Engineer:
      a slower manual crank opens the door)
- [ ] Test: every puzzle with 2 players, and confirm none can be solved solo

### Phase 9 — Core Game Systems
- [ ] Downed and revive system (30 second timer)
- [ ] Checkpoints and restart when the whole team is downed
- [ ] Collectible lore: notes, reel tapes, and photos with a journal menu
- [ ] Ping system: press a button to mark an item or spot for teammates
- [ ] Pause menu and settings (volume, mouse sensitivity, brightness)

### Phase 9.5 — Resident Evil Systems
- [ ] Health: injured state and healing items
- [ ] Safe rooms: monsters can't enter, calm music, save point
- [ ] Shared storage box in every safe room
- [ ] Crafting menu that combines two items using the Crafting table
- [x] Pouch upgrades that add inventory slots
- [ ] Map system that fills in as players explore and marks locked doors
- [ ] Locked doors that need key items, plus shortcut doors that open from
      one side only
- [ ] Melee weapons with durability
- [ ] Firearms: aiming, recoil, reloading, jamming for old guns, very limited
      ammo, and gunshots as the loudest noise event (save until Chapter 3)
- [ ] Boss fight framework: phases, arena triggers, and a reusable boss
      health/stun system (bosses are driven back or trapped, not killed)
- [ ] Test: every system with 2+ players, especially shared storage

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
4. **Maintenance Tunnels** — A **Vent Crawl** to unlock a door from the other
   side, then the **first monster encounter**: a chase where the Son senses
   it, the Journalist stuns it, and the Guard holds a door shut behind the team.
   *Gear: Fuse, Med Kit.*
5. **Elevator Room** — **Power Routing**: the Engineer repairs the elevator
   generator, others find two missing fuses, and the Guard holds off the
   monster. Then a **Dual Key Console** starts the elevator.

Tasks:
- [ ] Gray-box all five rooms
- [ ] Place puzzles and gear as listed above
- [ ] Confirm every character's ability is needed at least once
- [ ] One chase sequence through narrow tunnels
- [ ] Lore items that introduce the facility and each character's reason for coming
- [ ] Ending: elevator ride down, cable snaps, screen goes black, "Chapter 1 Complete"
- [ ] Replace placeholder art with real models, textures, and lighting
- [ ] Horror atmosphere: flickering lights, fog, ambient sounds, music stingers

### Phase 11 — Polish and Playtesting
- [ ] Playtest with real friends and write down what's confusing or not scary
- [ ] Teamwork check: did players have to talk and help each other? If anyone
      could finish a section alone, redesign it
- [ ] Fix bugs, especially multiplayer sync problems
- [ ] Balance ability cooldowns and monster speed
- [ ] Export builds for Windows

### Later (after Chapter 1 is fun)
- Steam lobbies and invites (GodotSteam)
- Echo voice mimic (stretch goal)
- Chapters 2 through 6, each with: a safe room, a boss encounter, at
  least one shortcut loop, a pouch upgrade (Ch. 2–5), and new weapons or tools
- Weapon roadmap: Ch. 1–2 melee only, Ch. 3 the guard revolver, Ch. 4
  shotgun, Ch. 5–6 modern guns from Ashby's security
- Unique monster designs for each chapter

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
