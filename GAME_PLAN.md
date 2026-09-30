# GAME_PLAN.md — Working Title: "Subject Zero"

A first-person, chapter-based, 1–4 player co-op horror game set in an abandoned
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

**Tone:** Dark, tense, retro. Flickering fluorescent lights, bunker doors,
reel-to-reel tapes, propaganda posters, gas masks, bulky old computers.

---

## Characters

Every player picks one character. Each character can only be picked once per
game. Each has one unique ability, so the team must work together.

| Character | Role | Ability | Held Item (first-person view) |
|---|---|---|---|
| **The Son** | Tracker | **Sense:** Hold a button to see nearby monsters glow through walls for 3 seconds. 20 second cooldown. | Parent's dog tags |
| **The Journalist** | Stunner / Lore | **Camera Flash:** Stuns a monster in front of her for 2 seconds. 15 second cooldown. Photographing evidence unlocks lore entries. | Old film camera |
| **The Engineer** | Fixer | **Repair:** Hold to fix generators, elevators, broken panels, and hack locked security doors. Only he can do this. | Wrench |
| **The Guard (Frank)** | Protector | **Strength:** Hold doors shut against monsters, move heavy objects, build barricades, carry a downed teammate. Moves slower and makes more noise. | Heavy flashlight |

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
| **Walkie-Talkie** | Lets two players hear each other from anywhere | Only 2 per chapter; very useful when split up |
| **Reel Tape** | Plays a lore recording on tape machines | Collectible story item |
| **Car Battery** | Powers a single heavy machine | Heavy item |

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

| # | Name | Spotlight | Goal | Ending |
|---|---|---|---|---|
| 1 | The Surface | Journalist | Break into the weather station, find the hidden elevator, learn the controls | First monster appears; elevator cable snaps, trapping the team below |
| 2 | Power Station | Engineer | Restore three generators to power the facility | Clues reveal the Engineer helped build the experiment machines |
| 3 | The Holding Cells | Guard | Reach the sealed lower levels | The truth about the night Frank sealed the doors |
| 4 | Subject Zero | Son | Enter the deepest lab | The Son learns what happened to his parent; final monster; team makes a choice |

**Build Chapter 1 fully before starting Chapter 2.**

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
- [ ] First-person camera with mouse look
- [ ] Walking, sprinting with stamina, crouching
- [ ] Head bob and footstep sounds (placeholder sounds are fine)
- [ ] Flashlight toggle with a narrow cone of light
- [ ] Interaction system: look at an object, press E, it responds
- [ ] Test: walk around the test room with the flashlight

### Phase 3 — Multiplayer Foundation
- [ ] `NetworkManager` autoload: host a game, join by IP, handle disconnects
- [ ] Simple main menu: Host, Join (IP box), Quit
- [ ] Spawn a player for each person who joins (up to 4)
- [ ] Sync player movement, camera direction, and flashlight on/off
- [ ] Each player only controls their own character
- [ ] Test: run two copies of the game on one computer and see both players move

### Phase 4 — Lobby and Character Select
- [ ] Lobby screen listing connected players
- [ ] Character select: each of the four characters can only be picked once
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
- [ ] Hearing: reacts to sprinting and the Guard's loud movement
- [ ] Sight: reacts to players in its view cone, especially flashlights
- [ ] Catching a player makes them "downed"
- [ ] Reacts to Journalist's stun and Guard-held doors
- [ ] Monster runs on the host and syncs to other players
- [ ] Test: the monster chases the right player and loses them when hidden

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
- Proximity voice chat
- Chapters 2, 3, and 4
- Unique monster designs for each chapter

---

## Monster Ideas (to design later)

- **Chapter 1:** A failed test subject stretched too tall for the tunnels,
  crawls on all fours in tight spaces.
- **Chapter 2:** Something fused with the facility's machinery, attracted to
  electricity. Restoring power wakes it up.
- **Chapter 3:** The people Frank sealed in, now changed. They still knock on doors.
- **Chapter 4:** Subject Zero, possibly connected to the Son's parent.

---

## Definition of Done for Each Task

1. It works in the Godot editor with no errors.
2. It works with at least 2 players (for anything multiplayer).
3. I have tested it myself.
4. It is committed to Git.
