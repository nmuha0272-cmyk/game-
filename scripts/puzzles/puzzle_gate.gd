class_name PuzzleGate
extends Node
## The "brain" of a puzzle. Watches some inputs (buttons, plates, keypads,
## other gates...) and switches some outputs (doors, lamps, lights).
##
## ALL = every input must be active at the same moment (both launch keys
##       turned together, both plates weighed down).
## ANY = one active input is enough.
## latch = once solved, it stays solved even if the inputs switch off.
## The host does the thinking; clients just get told the result (so their
## screens, prompts and panels match).

signal active_changed(active: bool)

enum Mode { ALL, ANY }

@export var inputs: Array[Node] = []
@export var outputs: Array[Node] = []
@export var mode: Mode = Mode.ALL
@export var latch := true
## Shown to everyone the first time the puzzle is solved.
@export var solved_message := ""

var is_active := false
var _was_solved := false


func _ready() -> void:
	for input in inputs:
		input.active_changed.connect(_evaluate.unbind(1))


func _evaluate() -> void:
	if not multiplayer.is_server() or (latch and is_active):
		return
	var active_count := inputs.filter(func(input: Node) -> bool: return input.is_active).size()
	var result := active_count == inputs.size() if mode == Mode.ALL else active_count > 0
	if result == is_active:
		return
	_set_active.rpc(result)
	for output in outputs:
		output.puzzle_set(result)
	if result and not _was_solved:
		_was_solved = true
		if not solved_message.is_empty():
			_announce.rpc(solved_message)


@rpc("authority", "call_local", "reliable")
func _set_active(value: bool) -> void:
	is_active = value
	active_changed.emit(value)


@rpc("authority", "call_local", "reliable")
func _announce(text: String) -> void:
	get_tree().call_group("player_hud", "show_message", text)
