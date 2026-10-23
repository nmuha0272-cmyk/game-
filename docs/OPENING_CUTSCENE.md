# Opening Cutscene - "Seven Missing"

## Overview
An opening cutscene that plays before the main menu, establishing Eli's backstory and motivation for investigating the Blackwater Weather Station.

## What Was Added

### Scene Files
- `scenes/main_menu/opening_cutscene.tscn` - The cutscene UI
- `scripts/ui/opening_cutscene.gd` - Cutscene logic and timing

### How It Works

The cutscene has two phases:

**Phase 1: Newspaper Article (8 seconds)**
- Shows a newspaper from October 2015: *The Blackwater Courier*
- Headline: "SEVENTH PERSON MISSING NEAR OLD WEATHER STATION"
- Reports on Marcus Bell (21) and Jenna Park (20) missing near the abandoned station
- Mentions 5 others missing since August, including reporter Daniel Marsh (Nora's source)
- References the 1999 sealing, "gas leak" cover story, 11 staff died including Dr. Maria Reyes and Sgt. Daniel Reyes

**Phase 2: Eli's Flashback (12 seconds)**
- Text: "That night..."
- Eli reading the article, remembering 1999 when his parents died
- Marcus and Jenna went in to find the truth about his parents
- Cole Brennan (who raised Eli) joins them
- Nora Vance lost her source (Daniel Marsh)
- Walter Kessler says he knows the way in
- Ends: "Seven people are missing. Four are going in after them."

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
- Now names Daniel Reyes (Volunteer 14)
- References TRANSFERRED — PROJECT ECHO
- Voice line about ECHO, not cancer

**personal_son_father_letter.tres**
- Updated epilogue: never came home, sealed in Level B in 1999
- Mom tried to get volunteers out, Walter killed her
- Voice line references Level B and ECHO

**personal_son_photo.tres**
- Updated to family photo: Maria (lab coat), Daniel (uniform), Eli (5 years old)
- Taken at Blackwater Station, 1998

**personal_son_drawing.tres**
- Updated to show both parents (uniform + lab coat)
- Text: "COME HOME SOON MOM AND DAD"

**personal_son_bracelet.tres**
- Renamed "Intake Bracelet - Volunteer 14"
- References PROJECT BASTION, TRANSFER TO LEVEL D

**personal_son_father_letter.tres**
- Updated epilogue: never came home, sealed in Level B in 1999
- Mom tried to get volunteers out, Walter killed her
- Voice line references Level B and ECHO

### The Story It Tells

1. **The Hook**: Seven people missing near the weather station since August 2015
2. **The Personal Stakes**: Two are Eli's best friends (Marcus & Jenna)
3. **The Backstory**: Eli's parents died in the 1999 "gas leak" at Deepwell
4. **The Mystery**: The station was sealed, but something's still happening
5. **The Team**: Four people going in — Eli, Cole (who raised him), Nora (lost her source), Walter (knows the way)
6. **The Legacy**: The experiments never stopped. Walter restarted them.

This establishes:
- Why Eli is investigating (personal loss + his friends are missing)
- What Project BASTION/ECHO did (human experiments, never stopped)
- The 1999 cover-up (gas leak story, both parents died)
- The villain (Walter Kessler, killed Mom, took Dad into ECHO)
- The team dynamics (Cole raised Eli, Nora seeks truth, Walter is the traitor)

### Testing

1. Launch the game
2. Cutscene plays automatically
3. Hold SPACE to skip if desired
4. Main menu appears after cutscene
5. In-game, find Eli's personal lore items to see the story continue