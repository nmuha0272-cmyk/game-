extends Control
## Shows character dialogue at the bottom of the screen with portraits.
## Lines appear in sequence with a typing effect.

signal dialogue_finished

@onready var portrait: TextureRect = %Portrait
@onready var character_name: Label = %CharacterName
@onready var dialogue_text: RichTextLabel = %DialogueText
@onready var background: Panel = %Background
@onready var continue_hint: Label = %ContinueHint

var current_dialogue: Array = []
var current_line := 0
var typing_speed := 0.03  # seconds per character
var is_typing := false
var skip_typing := false

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
		else:
			_next_line()
		get_viewport().set_input_as_handled()


## Play a sequence of dialogue lines.
## Format: [{"character": "Son", "text": "This place gives me the creeps..."}, ...]
func play_dialogue(lines: Array) -> void:
	current_dialogue = lines
	current_line = 0
	show()
	_show_line(0)


func _show_line(index: int) -> void:
	if index >= current_dialogue.size():
		_finish_dialogue()
		return
	
	var line: Dictionary = current_dialogue[index]
	var char_name: String = line.get("character", "???")
	var text: String = line.get("text", "")
	
	character_name.text = char_name
	dialogue_text.text = ""
	
	# Set portrait color (placeholder)
	if PORTRAITS.has(char_name):
		portrait.modulate = PORTRAITS[char_name]
	else:
		portrait.modulate = Color.WHITE
	
	continue_hint.hide()
	is_typing = true
	skip_typing = false
	
	# Type out the text character by character
	for i in range(text.length()):
		if skip_typing:
			dialogue_text.text = text
			break
		dialogue_text.text += text[i]
		await get_tree().create_timer(typing_speed).timeout
	
	is_typing = false
	continue_hint.show()


func _next_line() -> void:
	current_line += 1
	_show_line(current_line)


func _finish_dialogue() -> void:
	hide()
	dialogue_finished.emit()
	current_dialogue.clear()
	current_line = 0
