extends Interactable
## A reel-to-reel tape machine. Hold E with a Reel Tape to put it in: it
## plays out loud (as subtitles) for everyone nearby, and goes in the journal.
## Press E again later to replay the last tape.
## It's also a puzzle input: active once a tape has been played on it
## (or, with `required_lore` set, once that particular tape has).

signal active_changed(active: bool)

@export var required_lore := ""

@export var hearing_range := 14.0
@export var seconds_per_line := 4.0

var _tape_lore := ""
var _playing := false
var is_active := false

@onready var _hiss: AudioStreamPlayer3D = $Hiss
@onready var _reels: Node3D = $Reels


func get_hold_time(by: Player) -> float:
	return 1.0 if by.inventory.has_item("reel_tape") and not _playing else 0.0


func get_prompt(by: Player) -> String:
	if _playing:
		return "Playing..."
	if by.inventory.has_item("reel_tape"):
		return "[Hold E] Put in the reel tape and play it"
	if not _tape_lore.is_empty():
		return "[E] Play the tape again"
	return "Tape machine. Needs a reel tape."


func _on_interact(by: Player) -> void:
	if _playing:
		return
	var slot := by.inventory.find_item("reel_tape")
	if slot >= 0:
		var tape := by.inventory.server_remove(slot)
		_tape_lore = tape.get("lore", "")
	if _tape_lore.is_empty():
		return
	GameState.server_unlock_lore(_tape_lore, by.name.to_int())
	_play.rpc(_tape_lore)


@rpc("authority", "call_local", "reliable")
func _play(lore_id: String) -> void:
	var entry := Lore.get_entry(lore_id)
	if entry == null:
		return
	_tape_lore = lore_id
	_playing = true
	if not is_active and (required_lore.is_empty() or required_lore == lore_id):
		is_active = true
		active_changed.emit(true)
	_hiss.play()
	for line in entry.text.split("\n", false):
		var speaker := ""
		var words := line
		if ":" in line:
			speaker = line.get_slice(":", 0).strip_edges()
			words = line.substr(line.find(":") + 1).strip_edges()
		get_tree().call_group("player_hud", "show_subtitle_near", global_position, hearing_range,
				speaker, words, seconds_per_line)
		await get_tree().create_timer(seconds_per_line).timeout
	_hiss.stop()
	_playing = false


func _process(delta: float) -> void:
	if _playing:
		_reels.rotate_z(delta * 3.0)
