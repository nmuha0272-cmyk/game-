# Chapter 2: "Power Station" — Game Plan

**Spotlight:** Walter (The Engineer)
**Monster:** The Conduit (in the project files: `the_wired.tscn`, "The Wired"),
a test subject fused with the facility's wiring
**Goal:** get the dead lower levels running again by restoring **three
generators**, and find a way down
**Length target:** 90–120 minutes
**Level file:** `scenes/chapters/chapter_2/chapter_2.tscn`, built by
`tools/make_chapter2.py` (change the level there, not in the .tscn)

---

## Story

The elevator fell the last few floors at the end of Chapter 1. Everyone
survived, but they're trapped at the bottom of the shaft with no power and
no way back up.

### The opening: Eli and Nora argue (built)

Right after the crash, Eli and Nora have it out:
- **Nora** blames Eli: taking the elevator was his idea, and now they're
  stuck. She came for proof and for her source, Daniel Marsh.
- **Eli** fires back: she wanted her story. Marcus and Jenna came here
  because of him, and he's not turning back.
- Nora says what everyone is afraid of: "And if they're already dead?"
  Eli shuts her down.
- **Cole** breaks it up like a dad: "ENOUGH. Yelling is how that thing finds
  us."
- **Nora notices the cable was cut clean.** **Walter** says it's just rust.
  (A clue for the Chapter 4 twist: Walter cut it to trap them deeper.)

Built in `scripts/chapters/chapter2_narrative.gd`: it plays once at the start
of the chapter, as subtitles on every player's screen.

### How the Eli–Nora conflict grows and ends

| When | Moment |
|---|---|
| Start | The argument (above) |
| Radio Room | Nora wants to stop and photograph the files; Eli wants to keep moving. Cole makes them split the team, so they have to work apart and talk over walkie-talkies |
| Dormitory | Nora finds **Jenna's hair tie and Marcus's handwriting** on a bunk ("WE'RE ALIVE. GOING DOWN. —M & J"). She photographs it and **gives the photo to Eli** first, before her story |
| End of chapter | Eli: "Thanks, Nora. I mean it." Nora: "My source would have liked you." They're a team now |

### Walter's spotlight (with hidden clues)

Walter is in his element: only he can repair the generators and the
breaker rooms, and he knows the layout without a map. Players should like
him here. Clues hidden in plain sight:
- He knows a door code before anyone finds it ("Lucky guess").
- A Conduit test log says the subject's wiring was "installed per W.K. spec."
- The end of the chapter (in the GAME_PLAN): clues reveal Walter built the
  Goliath Chamber. He admits it with a sad cover story ("I was young. I
  didn't know what they'd use it for."). The team forgives him. (They're
  wrong to.)

### Eli and Cole

Cole keeps protecting Eli like a dad, and Eli keeps pushing back ("I'm not
five"). Cole carries the heaviest things and goes first through every dark
door.

---

## The Monster: The Conduit

A volunteer fused with the facility's power cables. It lives in the
walls and the wiring.
- **Attracted to electricity:** every generator or breaker the team turns on
  makes it hunt that area. Restoring power is also what wakes it up.
- **Feels you through metal:** hiding in a locker works, unless it saw you
  get in (or you're touching metal it's crawling through).
- **Lights die when it's close:** flickering, then darkness. Eli's Sense
  still shows it (and the team).
- **Weak to:** cutting the power to the room it's in (it gets stunned for a
  few seconds), Nora's flash, and Cole holding doors.
- **Voice:** it hears the walkie-talkie and voice chat like every monster.

---

## Sentry, the K-9 Experiment

### Who he was

A German Shepherd from Deepwell's **K-9 guard unit**. In 1999 the scientists
tested the **Goliath Serum** on the guard dogs to make "perfect sentries."
Most of them died. Sentry didn't.

Back then, a volunteer named **Daniel Reyes**, Eli's father, used to sneak him
scraps from the cafeteria and tell him about his little boy at home. When
Level B was sealed, Sentry was left behind, and for sixteen years he
survived alone in the dark, staying away from the other experiments.

### What he looks like

- As tall as a horse at the shoulder and **ten feet long**, but still clearly
  a German Shepherd: long snout, pointed ears, sloping back.
- Everything is stretched and overgrown: long legs, huge paws with cracked
  black claws that **click on the concrete**, and shoulders so overgrown that
  he moves a little lopsided.
- A row of yellowed **bone spikes** has grown through the skin along his spine.
- Patchy black-and-tan fur, with bald gray stretches covered in old scars and
  staple marks.
- One eye is milky and blind; the other is still a warm **amber-brown dog's eye**.
- One ear is torn and hanging.
- A rusted guard-dog **muzzle hangs broken** from his face by one strap.
- His old military collar, now far too small, still carries a tag:
  **K-9 SENTRY · UNIT 7 · DEEPWELL SECURITY**.

### How you meet him: the Kennels

A new section right after the **Dormitory**, where Eli finds his dad's dog
tag (Bunk 14):

1. The team enters the old **K-9 Kennels**: rows of bent cages, chewed
   bowls, a feeding chart with the dogs' names crossed out one by one.
   Only "SENTRY" isn't crossed out.
2. Heavy breathing. Claws clicking somewhere in the dark.
3. **Something enormous charges out of the dark kennels.** The camera
   shakes, the team is sure they're dead.
4. It **skids to a stop in front of Eli**, sniffs the dog tag in his hand,
   and **lies down at his feet, whining**. He has smelled Eli's father on
   that tag.
5. Cutscene line, Eli: *"You knew my dad... didn't you, boy?"*
   Cole: *"...Nobody make any sudden moves."*
6. From then on Sentry **never leaves Eli's side**.

Lore here: the **K-9 Unit Log** (the serum trials on the dogs), the feeding
chart, and a **photo of Daniel Reyes kneeling next to a normal-sized Sentry**
(Eli's personal item; voice line: *"That's my dad. He's... smiling."*).

### What he does: Eli's commands

**Sentry follows Eli everywhere** (a few steps behind him) and **only takes
orders from Eli**. Everyone else can pet him, but he ignores their orders.
Eli gives orders two ways:
1. **Command wheel (first):** hold a key (for example G), a wheel pops up
   with the orders below, pick one.
2. **Voice orders (added later):** Eli says the word into his microphone,
   for example *"Sentry, stay!"* or *"Sentry, quiet!"*. This needs a speech
   add-on for Godot (it only listens for the 7 order words, on Eli's
   computer). The command wheel always works too, in case it mishears.
   Careful: saying an order out loud is still noise the monsters can hear.

Sentry is run by the host like the monsters, so every player sees the same
thing.

| Command | What Sentry does | Limits |
|---|---|---|
| **Track** | Sniffs out a monster's scent trail and leads Eli along it (a glowing trail on the ground, for everyone) | 30 s cooldown |
| **Attack** | Charges a monster and **pins it** for a few seconds so the team can escape | 60 s cooldown; he gets hurt doing it (see below) |
| **Guard** | Stands over a downed teammate; monsters won't come close until someone revives them | Until revived, or he's needed |
| **Fetch** | Brings back an item through a vent or across a gap the players can't reach | Small items only |
| **Find** | Sniffs out hidden items and lore nearby and barks at them | 45 s cooldown |
| **Stay** | Stays put, for example **holding down a pressure plate** | Until called |
| **Quiet** | Stops barking and growling | Until told otherwise |

**Noise matters:** Sentry barks and growls when he senses monsters, and the
monsters can hear him like they hear voices. That warns the team but can
also give them away, so **Quiet** is important when hiding.

### Rules (so he's a helper, not a cheat)

- **He can't die.** If he's hurt too badly (after Attack, or if a monster
  catches him), he limps off to a hiding spot and comes back after about
  a minute. While he's gone, the team is on its own.
- **Teamwork still matters:** most puzzles still need two players. Sentry
  only replaces a player for small jobs (a plate, a fetch).
- **If nobody plays Eli:** Sentry follows whoever carries Daniel's dog tag,
  and only the simple orders work (Stay, Quiet, Fetch).
- **Other monsters hate him:** the experiments recognise another
  experiment. Some chases get worse when Sentry is with you.

### Sentry in later chapters

- **Chapter 3:** he tracks Cole's old trail through the cells; he growls at
  the door Cole sealed.
- **Chapter 4:** he growls at **Walter** before the twist (a clue nobody
  understands yet), and he's the one who finds **Marcus**.
- **Chapter 4–6:** he reacts to **Echo** (Eli's dad): he won't attack him and
  whines instead. A big emotional moment.
- **Ending:** whether Sentry makes it out is part of the final chapter.

---

## Sections (in play order)

**Built** = already in `tools/make_chapter2.py`. **To build** = new.

| # | Section | Status | What you do | Teamwork |
|---|---|---|---|---|
| 1 | **Crash Site** | Built | The wrecked elevator. A heavy door only stays open while **both pressure plates** are weighed down (players or the two car batteries from the wreck). The argument plays here | Someone stays on a plate, or the team carries both batteries |
| 2 | **Staff Lockers** | Built | Learn to hide: lockers, the "IF YOU HEAR IT: HIDE" sign | Tutorial |
| 3 | **Radio Room** | Built | Tune the radio to the emergency band; the frequency is on a chart next door and drifts. The broadcast gives the dormitory code. Checkpoint | One reads, one tunes |
| 4 | **Dormitory** | Built | Hide-and-seek: the Conduit drops in. Find **3 fuses** in the bunk rooms while it hunts you; lockers to hide. Marcus and Jenna's message on a bunk (to add) | Split up, cover each other |
| 4b | **K-9 Kennels** | To build | Meet **Sentry**: he charges out of the dark, smells Daniel's dog tag on Eli, and joins the team. Lore: K-9 Unit Log, feeding chart, photo of Daniel with Sentry | Story moment; learn his commands |
| 5 | **Generator Hall** | To build | The heart of the chapter: three generator rooms off one big hall. Each generator turned on wakes the Conduit in that wing | See the three puzzles below |
| 5a | Generator A: **Coolant** | To build | Walter repairs the pump while two players turn two coolant valves at the same time in different rooms (held switches) | Timing + calling out |
| 5b | Generator B: **Fuel** | To build | Carry heavy fuel drums along a dark catwalk (slow, Cole can carry two). Eli's Sense guides the carriers past the Conduit | Hunted Hallway |
| 5c | Generator C: **Breakers** | To build | A breaker pattern only shown on a monitor in the control booth; the breakers are two rooms away, and every wrong switch shocks the room and draws the Conduit | One reads, one flips |
| 6 | **Safe Room** | To build | First real save room: a storage box, a typewriter-style checkpoint, the **Field Pouch** upgrade, no monsters | Share gear |
| 7 | **Control Room** | To build | All three generators on: Walter brings the control panel online. Lore: the Conduit test log ("per W.K. spec") and Goliath Chamber blueprints | Story |
| 8 | **The Final Chase** | Built | The blast door opens, alarms go off, the Conduit bursts out: run down the long tunnel to the escape lift. The gate slams once everyone is inside | Don't leave anyone behind |
| 9 | **Ending** | To build | The lift goes down to Level B. Walter's "confession" about the Goliath Chamber. Eli and Nora make peace. "Chapter 2 Complete" | |

**Shortcut loop:** after the Generator Hall, a maintenance door opens back
to the Radio Room, so a wiped team doesn't have to re-walk the dormitory.

**Checkpoints:** Radio Room (built), Dormitory exit, Generator Hall, Safe
Room, Blast Tunnel (built).

---

## Lore to find

| Item | Type | Where | What it says |
|---|---|---|---|
| Radio Log | File (built) | Radio Room | The emergency band |
| Director's Memo | File (built) | Radio Room | |
| Guard Logbook | Personal: Cole (built) | Dormitory | Cole's 1999 log |
| Dog Tag, Bunk 14 | Personal: Eli (built) | Dormitory | Eli's dad's bunk |
| Level B Intake Log | File (built) | Dormitory | |
| "WE'RE ALIVE" | Personal: Eli (to add) | Dormitory bunk | Marcus and Jenna's message; proof they're alive |
| Conduit Test Log | File (to add) | Control Room | "Wiring installed per W.K. spec" |
| Goliath Chamber Blueprint (copy 2) | Personal: Walter (to add) | Control Room | Walter's signature, plain this time |
| Daniel Marsh's Notebook | Personal: Nora (to add) | Generator B | Her source got this far. Last page: "The engineer is still here." |
| Maria Reyes's Badge | Personal: Eli (to add) | Safe Room | His mom's ID badge; Eli's voice line |
| K-9 Unit Log | File (to add) | K-9 Kennels | The Goliath Serum trials on the guard dogs; most died, "Unit 7 (SENTRY) survived" |
| Feeding Chart | Environmental (to add) | K-9 Kennels | Dogs' names crossed out one by one, all but SENTRY |
| Daniel and Sentry | Personal: Eli (to add) | K-9 Kennels | A photo of Eli's dad kneeling next to a normal-sized Sentry |

---

## Gear

- Batteries, flares, med kits (scarce), walkie-talkies
- **Field Pouch** (+1 storage) in the Safe Room
- Melee weapons to craft (pipe + duct tape...), little ammo
- Car batteries (heavy) at the Crash Site

---

## Build Tasks

- [x] Crash Site, Staff Lockers, Radio Room, Dormitory hide-and-seek, Final Chase, escape lift
- [x] Opening argument between Eli and Nora (`chapter2_narrative.gd`)
- [ ] Marcus and Jenna's "WE'RE ALIVE" message in the Dormitory
- [ ] K-9 Kennels and the meeting with Sentry (cutscene)
- [ ] Sentry companion: follows Eli, host-controlled, noise the monsters hear
- [ ] Sentry follows Eli and only takes orders from Eli
- [ ] Eli's command wheel: Track, Attack, Guard, Fetch, Find, Stay, Quiet
- [ ] Later: voice orders ("Sentry, stay!") with a speech add-on, wheel as backup
- [ ] Sentry's model (the team will make or supply it; used as given)
- [ ] Generator Hall with the three generator puzzles (Coolant, Fuel, Breakers)
- [ ] The Conduit hunts the wing of each generator that's turned on
- [ ] Safe Room with storage box and the Field Pouch
- [ ] Control Room and the Walter clues
- [ ] Shortcut loop back to the Radio Room
- [ ] Ending: Walter's "confession", Eli and Nora make peace
- [ ] New lore entries listed above
- [ ] Playtest: every puzzle needs at least two players; a solo backup for each
