extends Node3D
## A breaker panel: a row of switches (BreakerSwitch children) that must be
## flipped UP or DOWN to match a pattern. The HOST picks the pattern; a
## wiring diagram somewhere else shows it (a CodeDisplay with this panel as
## its source). Optionally it only works once `powered_by` is active (the
## generator running). When everything matches, it becomes active for good.

signal active_changed(active: bool)
signal code_changed(code: String)

@export var powered_by: Node
@export var switch_count := 5

var is_active := false
var pattern: Array = []  # true = UP

var _switches: Array = []


func _ready() -> void:
	for child in get_children():
		if child.has_method("set_up"):
			_switches.append(child)
			child.flipped.connect(_on_flipped)
	if powered_by:
		powered_by.active_changed.connect(_on_flipped.unbind(1))
	if multiplayer.is_server():
		var new_pattern := []
		for i in _switches.size():
			new_pattern.append(randi() % 2 == 0)
		# Never already solved: all switches start DOWN.
		if not new_pattern.has(true):
			new_pattern[randi() % new_pattern.size()] = true
		_set_pattern(new_pattern)
	else:
		_request_state.rpc_id(1)


func get_display_code() -> String:
	var parts := []
	for i in pattern.size():
		parts.append("%d %s" % [i + 1, "UP" if pattern[i] else "DOWN"])
	return "   ".join(parts)


func _on_flipped() -> void:
	if not multiplayer.is_server() or is_active:
		return
	if powered_by and not powered_by.is_active:
		return
	for i in _switches.size():
		if _switches[i].is_up != pattern[i]:
			return
	_set_active.rpc()


@rpc("any_peer", "reliable")
func _request_state() -> void:
	if multiplayer.is_server():
		var id := multiplayer.get_remote_sender_id()
		_set_pattern_rpc.rpc_id(id, pattern)
		if is_active:
			_set_active.rpc_id(id)


func _set_pattern(new_pattern: Array) -> void:
	_set_pattern_rpc.rpc(new_pattern)


@rpc("authority", "call_local", "reliable")
func _set_pattern_rpc(new_pattern: Array) -> void:
	pattern = new_pattern
	code_changed.emit(get_display_code())


@rpc("authority", "call_local", "reliable")
func _set_active() -> void:
	is_active = true
	active_changed.emit(true)
