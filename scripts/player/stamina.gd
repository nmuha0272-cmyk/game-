class_name Stamina
extends Node
## Keeps track of how much sprint energy the player has left.
## Drains while sprinting, refills after a short rest.

signal changed(current: float, maximum: float)

@export var max_stamina := 100.0
## Stamina lost per second while sprinting.
@export var drain_rate := 25.0
## Stamina regained per second while resting.
@export var regen_rate := 15.0
## Seconds to wait after sprinting before stamina starts refilling.
@export var regen_delay := 1.0
## If stamina hits zero, you can't sprint again until it refills this much.
@export var recover_threshold := 30.0

## Set to true by the movement script while the player is sprinting.
var draining := false
var current := 0.0

var _exhausted := false
var _regen_timer := 0.0


func _ready() -> void:
	current = max_stamina


func can_sprint() -> bool:
	return current > 0.0 and not _exhausted


func _physics_process(delta: float) -> void:
	var before := current

	if draining:
		current = maxf(current - drain_rate * delta, 0.0)
		_regen_timer = regen_delay
		if current == 0.0:
			_exhausted = true
	elif _regen_timer > 0.0:
		_regen_timer -= delta
	else:
		current = minf(current + regen_rate * delta, max_stamina)

	if _exhausted and current >= recover_threshold:
		_exhausted = false

	if current != before:
		changed.emit(current, max_stamina)
