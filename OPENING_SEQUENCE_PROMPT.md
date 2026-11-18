# OPENING_SEQUENCE_PROMPT.md — Paste this into Claude Code

Copy everything below the line into Claude Code, in your Unity project.

---

Please build Deepwell's opening sequence in Unity: the home screen, the
car cutscene, meeting the other players, and character select from inside
the car's trunk. Read GAME_PLAN.md, CHARACTER_MODEL_GUIDE.md, and
MONSTER_GUIDE.md first so names, story, and looks match.

Before you start, look at the project and tell me:
- the Unity version and render pipeline (HDRP, URP, or Built-in)
- what's already built (networking, player controller, any menu)
Then give me a short plan and wait for my OK. Ask me if anything below is
unclear instead of guessing.

Use placeholder shapes for anything I don't have a model for yet (capsules
for people, boxes for the car). Every placeholder should be easy to swap for
a real model later. Use Cinemachine for cameras and Timeline for the
cutscenes. Everything must work with a controller and with mouse and keyboard.

## The flow

```
HOME SCREEN (car driving, only Eli + Cole inside)
   │  player hosts or joins, host presses Play
   ▼
CUTSCENE 1: "THE ROAD" (Eli and Cole talk in the car)
   ▼
CUTSCENE 2: "THE MEETING" (car pulls into a closed gas station,
            Nora and Walter are waiting)
   ▼
CHARACTER SELECT: Eli opens the trunk; camera is INSIDE the trunk
            looking up at the four of them; players pick
   ▼
GAMEPLAY: Chapter 1 starts at the Blackwater Weather Station gate
```

## 1. Home screen

- A car (Eli's father's old 1990s maroon sedan) driving down a dark,
  foggy two-lane forest road at night, with headlights, passing trees, and
  slight bumps. The world scrolls past the car so it looks like it's driving.
- **Only two people in the car: Eli driving, Cole in the passenger seat.**
  The back seat is empty except for a duffel bag.
- Slow camera drift around the outside of the car.
- Title "DEEPWELL" and buttons on the left: Host Game, Join Game,
  Settings, Credits, Quit. Join shows an IP field (or the lobby system from
  GAME_PLAN.md if it exists). Settings: volume, mouse sensitivity,
  brightness, fullscreen, subtitles on/off.
- After hosting or joining, show a small lobby panel with connected players
  (1–4). The host sees a **Play** button.
- When the host presses Play, everyone goes into Cutscene 1 together.

## 2. Cutscene 1: "The Road" (about 60–90 seconds)

Inside the car. Cameras: over Cole's shoulder at Eli, a close-up of Eli's
hands on the wheel with the dog tag hanging from the mirror, a shot through
the windshield at the fog, a close-up of Cole looking out the window.

Show **subtitles** for every line (with the speaker's name), and leave a
voice-line slot for each line so I can add voice acting later. Use the IDs
below for the voice files.

**Script:**

> *(Rain-wet road. Wipers. The dog tag swings from the rearview mirror.)*
>
> **ELI** `road_01`: You ever hear of a place called Blackwater?
>
> **COLE** `road_02`: *(still looking out the window)* Should I have?
>
> **ELI** `road_03`: It's a weather station. Middle of nowhere. My dad's last
> letter came from a post office twenty miles from it.
>
> **COLE** `road_04`: Eli...
>
> **ELI** `road_05`: He's not the only one. I found eleven people who went
> missing around there since the sixties. Soldiers. Volunteers. A reporter's
> source, last year. Nobody looks for them. Nobody even asks.
>
> **COLE** `road_06`: Some people don't want to be found.
>
> **ELI** `road_07`: *(quiet)* And some people don't get a choice.
>
> *(A long pause. Cole finally looks at him.)*
>
> **COLE** `road_08`: You've been thinking about this since you were five.
>
> **ELI** `road_09`: Since the day they handed my mom a folded flag and told
> her it was a training accident.
>
> *(Cole looks down at his hands. He doesn't answer for a moment.)*
>
> **COLE** `road_10`: *(changing the subject)* We're not doing this alone.
> We're meeting some people.
>
> **ELI** `road_11`: People? You said it'd be just us.
>
> **COLE** `road_12`: A reporter who's been chasing the same story. And a man
> who used to work there.
>
> **ELI** `road_13`: Worked *there*? You trust him?
>
> **COLE** `road_14`: I don't trust anybody. *(beat)* Except you, kid. Take
> the next left.
>
> *(Headlights catch a faded sign: "PINE HOLLOW GAS — 1 MI". Eli turns.)*

## 3. Cutscene 2: "The Meeting" (about 30–45 seconds)

- A **closed, run-down gas station** at about 3:30 AM: one buzzing
  light over the pumps, a dark diner window, fog, puddles.
- **Nora** leans against her car, camera around her neck. **Walter** stands
  beside an old pickup truck, nervous, with a toolbox.
- The sedan pulls in and stops. Eli and Cole get out.

> **NORA** `meet_01`: You're late.
>
> **COLE** `meet_02`: We're here. Eli, this is Nora Vance. She's been chasing
> Blackwater for three years.
>
> **NORA** `meet_03`: *(to Eli)* I read about your father. I'm sorry.
>
> **COLE** `meet_04`: And that's Walter.
>
> **WALTER** `meet_05`: *(not looking at anyone)* I worked maintenance there.
> A long time ago. I know the tunnels. *(beat)* I didn't think I'd ever go
> back.
>
> **ELI** `meet_06`: Then why are you?
>
> **WALTER** `meet_07`: *(after a long pause)* Because I helped build it.
>
> *(Silence. Cole walks to the back of the sedan.)*
>
> **COLE** `meet_08`: Gear's in the trunk. Grab what you need. We go in
> before sunrise.
>
> *(Eli opens the trunk. Cut to black for a moment, then character select.)*

**Skipping:** any player can press and hold a button to vote to skip.
The cutscene skips when **every player** has voted (or the host holds it).
Show "Hold [button] to skip (1/4)" in the corner. Cutscenes are skippable
on later playthroughs only after they've been seen once by that player.

## 4. Character select: from inside the trunk

- **Camera POV: lying inside the open trunk, looking up and out.** The
  trunk lid is open above, framing the shot. The four characters stand in
  a row behind the car looking down into the trunk, lit by the trunk light
  and the gas station light behind them, with fog in the background.
- In the trunk (bottom of the frame): flashlights, walkie-talkies, a
  crowbar, Cole's duffel bag, Nora's camera bag, Walter's toolbox.
- Order left to right: **Walter, Nora, Eli, Cole.**
- **Hovering a character** (mouse over them, or left/right on a controller):
  - that character steps slightly forward and gets a soft highlight
  - the camera eases a little toward them (a small push, not a big move)
  - an info panel shows their name, role, short bio, abilities, and a
    quote. Use the text from CHARACTER_MODEL_GUIDE.md and the character
    table in GAME_PLAN.md.
- **Picking a character:**
  - the character reaches into the trunk and grabs their item
    (Eli: flashlight + dog tag, Cole: his heavy flashlight, Nora: her camera,
    Walter: his toolbox and wrench)
  - their name gets a player tag ("PLAYER 2") above it
  - **each character can only be picked once**; taken characters show
    "TAKEN" and can't be selected
  - players can unpick and choose again until the host starts
- **Big name cards along the bottom** of the screen as a second, easy way
  to pick (hover a card = same as hovering the character).
- Characters nobody picks stay as **AI-free placeholders** that don't come
  into the level (or follow the 1–4 player rules in GAME_PLAN.md).
- When everyone has picked, the host sees **"Start (all ready)"**. Players
  can also press Ready. When the host starts, fade to black.

## 5. Into the game

- Fade from black to the **Blackwater Weather Station gate** (Chapter 1 start,
  see BUILDING_DESCRIPTION.md and the Chapter 1 plan in GAME_PLAN.md).
- Each player spawns as their chosen character in first person, holding
  their item.
- Show "CHAPTER 1: THE SURFACE" in the corner for a few seconds.
- If the Chapter 1 scene doesn't exist yet, spawn players in a simple test
  area so we can test everything up to this point.

## 6. Multiplayer rules

- The **host controls** the flow: when cutscenes start, skip votes, which
  characters are taken, and when the game starts. Clients send requests.
- Every player sees the same cutscene at the same time.
- If a player joins late (during a cutscene), they wait on a "Joining..."
  screen and enter at character select.
- If a player leaves during character select, their character is free
  again.

## 7. Files and structure

- Separate scenes: `MainMenu`, `Opening` (both cutscenes + trunk select),
  and the gameplay scene. Or one scene with clear sections, whichever fits
  the project best (explain your choice).
- A `CharacterData` ScriptableObject for each character (name, role, bio,
  abilities, quote, color, model prefab, held item) so the select screen
  reads from data, not hard-coded text.
- A dialogue/subtitle system that reads lines from a data file (speaker,
  text, voice clip ID) so I can edit the script without touching code.
- Put my real models in later at: `Assets/Models/Characters/` (Eli, Cole,
  Nora, Walter), `Assets/Models/Vehicles/` (sedan, Nora's car, Walter's
  pickup), `Assets/Models/Environment/` (gas station).

## 8. When you're done

Tell me exactly how to test it:
1. with one player (me alone)
2. with two players on the same computer (two instances, or ParrelSync /
   Multiplayer Play Mode if available)

And list anything you left as a placeholder.
