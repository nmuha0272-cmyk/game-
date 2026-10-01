extends Node3D
## A signal lamp that blinks a keypad's code in Morse code, over and over.
## Short flash = dot, long flash = dash. Someone reads the blinks out loud,
## and someone else looks them up on the translation sheet.

const MORSE := {
	"1": ".----", "2": "..---", "3": "...--", "4": "....-", "5": ".....",
	"6": "-....", "7": "--...", "8": "---..", "9": "----.", "0": "-----",
}

@export var source: Node
## Optional: it only blinks while this piece is active (a switch someone holds).
@export var powered_by: Node
@export var dot_time := 0.3
@export var dash_time := 0.9
@export var gap_time := 0.35
@export var letter_gap := 1.4
@export var repeat_gap := 3.5

var _steps: Array = []  # [is_on, seconds]
var _index := 0
var _timer := 0.0
var _material: StandardMaterial3D

@onready var _light: OmniLight3D = $Light
@onready var _bulb: MeshInstance3D = $Bulb


func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.emission_enabled = true
	_bulb.material_override = _material
	source.code_changed.connect(_build_steps.unbind(1))
	_build_steps()


func _build_steps() -> void:
	_steps.clear()
	for digit in source.get_display_code():
		for symbol in MORSE.get(digit, ""):
			_steps.append([true, dot_time if symbol == "." else dash_time])
			_steps.append([false, gap_time])
		_steps.append([false, letter_gap])
	_steps.append([false, repeat_gap])
	_index = 0
	_timer = 0.0


func _process(delta: float) -> void:
	if _steps.is_empty():
		return
	_timer -= delta
	if _timer <= 0.0:
		_index = (_index + 1) % _steps.size()
		_timer = _steps[_index][1]
	var on: bool = _steps[_index][0] and (powered_by == null or powered_by.is_active)
	_light.visible = on
	_material.albedo_color = Color(1, 0.9, 0.6) if on else Color(0.15, 0.13, 0.1)
	_material.emission = Color(1, 0.85, 0.5) * (3.0 if on else 0.0)
