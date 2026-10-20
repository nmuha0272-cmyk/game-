extends Control
## Shows character dialogue at the bottom of the screen with portraits.
## Lines appear in sequence with a typing effect. A cutscene director can
## take over with `external_control` + `show_line()` instead of local input.

signal dialogue_finished
## Emitted when the player wants to move on to the next line while
## `external_control` is on (the director decides what happens next).
signal continue_pressed

@onready var portrait: ColorRect = %Portrait
@onready var character_name: Label = %CharacterName
@onready var dialogue_text: RichTextLabel = %DialogueText
@onready var background: Panel = %Background
@onready var continue_hint: Label = %ContinueHint

var current_dialogue: Array = []
var current_line := 0
var typing_speed := 0.03  # seconds per character
var is_typing := false
var skip_typing := false
## True while a cutscene decides which line is on screen. Local input then
## only skips the typing effect and asks the director to continue.
var external_control := false

## Bumped whenever a new line replaces the old one, so a typing loop from
## a previous line stops instead of writing over the new text.
var _line_gen := 0

# Character portraits (placeholder colors for now)
const PORTRAITS := {
	"Son": Color(0.42, 0.27, 0.16),
	"Journalist": Color(0.62, 0.5, 0.36),
	"Engineer": Color(0.14, 0.17, 0.3),
	"Guard": Color(0.3, 0.33, 0.22),
}


func _ready() -> void:
	hide()
	add_to_group("dialogue_box")


func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		if is_typing:
			skip_typing = true
		elif external_control:
			continue_pressed.emit()
		else:
			_next_line()
		get_viewport().set_input_as_handled()


## Play a sequence of dialogue lines (player-input driven).
## Format: [{"character": "Son", "text": "This place gives me the creeps..."}, ...]
func play_dialogue(lines: Array) -> void:
	start_dialogue(lines)
	_show_line(0)


## Set up the lines without showing the first one — a cutscene director
## calls show_line() itself so its camera cut and the text land together.
func start_dialogue(lines: Array) -> void:
	current_dialogue = lines
	current_line = 0
	show()


## Show one specific line (used by a director, possibly over the network).
func show_line(index: int) -> void:
	current_line = index
	_show_line(index)


func _show_line(index: int) -> void:
	if index >= current_dialogue.size():
		_finish_dialogue()
		return
	
	var line: Dictionary = current_dialogue[index]
	var char_name: String = line.get("character", "???")
	var text: String = line.get("text", "")
	
	# Stop any typing still running from the previous line.
	_line_gen += 1
	var gen := _line_gen
	skip_typing = false
	
	character_name.text = char_name
	dialogue_text.text = ""
	
	# Set portrait color (placeholder)
	if PORTRAITS.has(char_name):
		portrait.modulate = PORTRAITS[char_name]
	else:
		portrait.modulate = Color.WHITE
	
	continue_hint.hide()
	is_typing = true
	
	# Type out the text character by character
	for i in range(text.length()):
		if gen != _line_gen:
			return  # a newer line took over
		if skip_typing:
			dialogue_text.text = text
			break
		dialogue_text.text += text[i]
		await get_tree().create_timer(typing_speed).timeout
	
	if gen != _line_gen:
		return
	is_typing = false
	continue_hint.show()


func _next_line() -> void:
	current_line += 1
	_show_line(current_line)


func _finish_dialogue() -> void:
	_line_gen += 1
	hide()
	dialogue_finished.emit()
	current_dialogue.clear()
	current_line = 0
	is_typing = false


## Hides everything without emitting `dialogue_finished` — used when a
## cutscene director ends the scene and takes over restoring the screen.
func stop_dialogue() -> void:
	_line_gen += 1
	hide()
	current_dialogue.clear()
	current_line = 0
	is_typing = false
	skip_typing = false
