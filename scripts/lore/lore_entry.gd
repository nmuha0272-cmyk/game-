class_name LoreEntry
extends Resource
## One piece of story: a file, a reel tape, a photo, a poster or a personal
## item. Each one is a small .tres file in res://lore/ (named after its id),
## so new lore can be written in the Godot editor without code.

enum Type { FILE, TAPE, PHOTO, PERSONAL }

## Unique name, also the file name (lore/<id>.tres).
@export var id := ""
@export var title := ""
@export var type: Type = Type.FILE
## What the journal shows. For tapes, one line per spoken line:
## "SPEAKER: what they say". Lines are shown as subtitles one at a time.
@export_multiline var text := ""
## Optional recorded audio (tapes, voice lines). Text is shown if empty.
@export var audio: AudioStream
## For personal items: whose it is (see characters.gd), or -1.
@export var owner_character := -1
## For personal items: what the owner says out loud when they find it.
@export_multiline var voice_line := ""
