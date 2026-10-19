# Opening Cutscene - "The Mystery Illness"

## Overview
An opening cutscene that plays before the main menu, establishing Eli's backstory and motivation for investigating the weather station.

## What Was Added

### Scene Files
- `scenes/main_menu/opening_cutscene.tscn` - The cutscene UI
- `scripts/ui/opening_cutscene.gd` - Cutscene logic and timing

### How It Works

The cutscene has two phases:

**Phase 1: Newspaper Article (8 seconds)**
- Shows a newspaper from October 1992
- Headline: "MYSTERY ILLNESS CLAIMS ANOTHER VETERAN"
- Reports on David Chen's death and 17 other former volunteers dying
- Doctors question the "cancer" diagnosis - cell patterns don't match
- Mentions Project IRONWOOD and the "old weather station"

**Phase 2: Hospital Scene (12 seconds)**
- Flashback to six months earlier
- Eli at his father's bedside
- David Chen reveals the truth: "It's not cancer, son"
- Shows the dog tag: "VOLUNTEER 14 - IRONWOOD"
- David warns Eli to stay away from the weather station
- Eli decides he can't make that promise
- Text: "Three days later, David Chen was gone."

**Controls:**
- Hold SPACE to skip (requires 1 second hold to prevent accidental skips)
- Automatically transitions to main menu when finished

### Integration

Modified files:
- `scenes/main.tscn` - Added OpeningCutscene node, MainMenu starts hidden
- `scripts/main.gd` - Added cutscene.finished signal handler to show main menu

### Updated Lore Items

To tie into the cutscene backstory:

**personal_son_volunteer_id.tres**
- Now explicitly names David Chen
- References his death from the mysterious illness
- Eli's voice line mentions the fake cancer diagnosis

**personal_son_father_letter.tres**
- Added epilogue text about the delayed effects
- New voice line about the experiments never leaving his body

## The Story It Tells

1. **The Hook**: Seventeen veterans are dying mysteriously
2. **The Mystery**: Doctors can't explain it - looks like cancer but isn't
3. **The Personal Stakes**: Eli's father was one of them
4. **The Warning**: David Chen told Eli to stay away
5. **The Motivation**: Eli can't ignore seventeen deaths and government lies
6. **The Legacy**: The experiments killed them slowly, decades later

This establishes:
- Why Eli is investigating (personal loss + justice for 17 men)
- What Project IRONWOOD did (human experiments disguised as vitamins)
- The delayed effects (the serum kills you 30 years later)
- The cover-up (DOD denies everything, doctors call it cancer)
- The tragedy (Eli watched his father waste away, knowing the truth)

## Testing

1. Launch the game
2. Cutscene plays automatically
3. Hold SPACE to skip if desired
4. Main menu appears after cutscene
5. In-game, find Eli's personal lore items to see the story continue
