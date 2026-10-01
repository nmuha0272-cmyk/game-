class_name PuzzleInput
extends Interactable
## Base for puzzle pieces players use (buttons, key consoles, levers, hold
## switches, fuse boxes, work stations...). The HOST decides when a piece is
## "active" and tells everyone. A PuzzleGate listens to pieces and opens
## doors, turns on lights, etc.
##
## Optional visuals: a part that moves/turns when active, and a lamp that
## glows green when active (red when not).
## Optional `requires`: another piece that must be active before this one
## can be used (for example a switch someone else has to hold).

signal active_changed(active: bool)

@export var moving_part: Node3D
@export var active_rotation := Vector3.ZERO
@export var active_offset := Vector3.ZERO
@export var lamp: MeshInstance3D
@export var requires: Node
@export var requires_message := "Not yet."

var is_active := false

var _rest_position := Vector3.ZERO
var _rest_rotation := Vector3.ZERO
var _lamp_material: StandardMaterial3D


func _ready() -> void:
	if moving_part:
		_rest_position = moving_part.position
		_rest_rotation = moving_part.rotation_degrees
	if lamp:
		_lamp_material = StandardMaterial3D.new()
		_lamp_material.emission_enabled = true
		lamp.material_override = _lamp_material
	_update_visuals()


func requirement_met() -> bool:
	return requires == null or requires.is_active


func get_prompt(by: Player) -> String:
	if not requirement_met():
		return requires_message
	return super(by)


## Host only.
func server_set_active(value: bool) -> void:
	if multiplayer.is_server() and value != is_active:
		_set_active.rpc(value)


@rpc("authority", "call_local", "reliable")
func _set_active(value: bool) -> void:
	is_active = value
	_update_visuals()
	_on_active_changed(value)
	active_changed.emit(value)


## Child scripts can add extra effects here.
func _on_active_changed(_active: bool) -> void:
	pass


func _update_visuals() -> void:
	if moving_part:
		var tween := create_tween().set_parallel()
		tween.tween_property(moving_part, "position",
				_rest_position + (active_offset if is_active else Vector3.ZERO), 0.25)
		tween.tween_property(moving_part, "rotation_degrees",
				_rest_rotation + (active_rotation if is_active else Vector3.ZERO), 0.25)
	if _lamp_material:
		var color := Color(0.1, 1.0, 0.25) if is_active else Color(1.0, 0.12, 0.05)
		_lamp_material.albedo_color = color
		_lamp_material.emission = color
