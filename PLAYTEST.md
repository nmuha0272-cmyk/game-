# Subject Zero: Chapter 1 Playtest

A sheet to use when you play Chapter 1 with friends. Fill in one copy per
session. Don't explain the puzzles before you start. Watching where people
get stuck is the whole point.

## Setting up

1. Everyone gets `SubjectZero.exe` (from `SubjectZero_Windows.zip`, or
   export it yourself: Godot > Project > Export > Windows > Export Project).
2. The host clicks **Host**. Everyone else types the host's IP and clicks **Join**.
   - Same house / same Wi-Fi: use the host's local IP (like `192.168.1.20`).
     Find it by running `ipconfig` in a Command Prompt.
   - Different houses: the easiest way is a free virtual LAN app like
     **Tailscale** or **Radmin VPN**. Everyone joins the same network, and you
     use the IP that app shows. (Or the host can forward port **7777 UDP**
     on their router.)
   - Windows may ask to allow the game through the firewall: click **Allow**.
3. Everyone picks a character. Playing alone works too (solo mode: things
   you hold up stay propped for 15 s, and launch keys stay turned for 10 s),
   but test with friends too: that's how the game is meant to be played.

Controls: WASD move, Shift sprint, Ctrl crouch, E interact (hold for some
things), Q ability, F flashlight, Left Mouse use item, G drop, T give,
1-3 / mouse wheel switch slot, J journal, Z or middle mouse ping, Esc pause.

## Session info

| | |
|---|---|
| Date | |
| Players and characters | |
| Total time to finish (or where you quit) | |
| Times the whole team went down | |

## Room by room

For each room, write how long it took, where people got stuck, and whether it
was scary. Tick the questions.

### 1. Outside the fence (gate, crowbar)
- [ ] Did anyone figure out on their own that Frank lifts the gate?
- [ ] Did they find the crowbar in the yard without help?
- Time / notes:

### 2. Station office (tape, monitor switch, keypad, cabinet, keycard)
- [ ] Did they understand the screen needs BOTH the tape AND the hall switch?
- [ ] Did one person read the code out loud to the other?
- [ ] Did they find the stairwell behind the filing cabinet?
- Time / notes:

### 3. Hidden stairwell (batteries start draining)
- [ ] Did anyone notice the flashlight draining and share batteries?
- Time / notes:

### 4. Tunnels (vent crawl, Long Man chase)
- [ ] Did they figure out the vent: one holds, one crawls, opens the bolt?
- [ ] The chase: scary? Too hard? Too easy?
- [ ] Did the Son use Sense / the Journalist use the flash / Frank hold the door?
- [ ] If someone got caught, did the others come back to help them up?
- Time / notes:

### 5. Elevator room (fuses, generator, Containment Order, two keys)
- [ ] Did they find both fuses?
- [ ] Did they understand the consoles need the Containment Order read?
- [ ] Did they work out that both keys turn at the same time (counting "3, 2, 1")?
- Time / notes:

### Ending (elevator, cable snaps)
- [ ] Did the ending land? (Reactions?)

## Big questions (after playing)

1. What was the most confusing moment?
2. What was the scariest moment? What wasn't scary at all?
3. Was there any part one person did alone while the others waited?
   (If yes: that part needs a redesign. "No solo solutions.")
4. Did everyone's character feel useful? Which one felt useless?
5. Did you have to talk to each other? When?
6. Any bugs? (Things floating, falling through floors, doors stuck, someone
   seeing something different from everyone else.)

## Balance numbers (change these after playtesting)

| What | Value | Where to change it |
|---|---|---|
| Walk / sprint speed | 3.5 / 6.0 m/s | `scripts/player/player_movement.gd` |
| Sprint stamina | 4 s of sprint, refills after 1 s rest | `scripts/player/stamina.gd` |
| Frank speed | 0.85x (sprint 5.1) | `scripts/characters.gd` |
| Long Man chase speed | 4.2 m/s | `chase_speed` in `scripts/monsters/monster.gd` |
| Long Man gives up a chase | 3 s without seeing you | `lose_target_time` in `monster.gd` |
| After catching someone | walks away, ignores everyone for 6 s | `catch_cooldown` in `monster.gd` |
| Journalist flash | stuns 3 s (2 s x1.5 light hate), 12 s cooldown | `scripts/abilities/journalist_flash.gd` |
| Son Sense | 4 s glow, 25 m range, 15 s cooldown | `scripts/abilities/son_sense.gd` |
| Downed bleed-out | 30 s (help up takes 3 s) | `scripts/player/downed_state.gd` |

Rules of thumb:
- **The chase was way too easy:** raise `chase_speed` a little (4.2 → 4.5).
- **Everyone kept dying in the chase:** lower it (4.2 → 4.0), or raise the flash stun.
- **Nobody used the Son's Sense:** shorten its cooldown or make it last longer.
