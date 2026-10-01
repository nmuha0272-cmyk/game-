class_name Flashlight
extends SpotLight3D
## Turns the flashlight on and off with the flashlight key (F).
## The battery drains while it's on and it flickers when nearly empty.
## Batteries (the gear item) recharge it. Only the owner tracks the charge;
## everyone else just sees whether it's on.

signal switched(is_on: bool)

@export var starts_on := false
## Seconds of light from a full battery.
@export var battery_life := 180.0
## Below this charge (0 to 1) the light starts to flicker.
@export var low_battery := 0.15

## 0 = empty, 1 = full.
var charge := 1.0

var _base_energy := 0.0


func _ready() -> void:
	_base_energy = light_energy
	visible = starts_on


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("flashlight"):
		set_on(not visible)


func set_on(value: bool) -> void:
	if value and charge <= 0.0:
		get_tree().call_group("player_hud", "show_message", "Your flashlight battery is dead.")
		return
	visible = value
	switched.emit(value)


func _process(delta: float) -> void:
	if not is_multiplayer_authority() or not visible:
		return
	charge = maxf(charge - delta / battery_life, 0.0)
	if charge <= 0.0:
		set_on(false)
	elif charge < low_battery and randf() < 0.08:
		light_energy = _base_energy * randf_range(0.1, 0.6)  # Dying battery flicker.
	else:
		light_energy = _base_energy * (0.6 + 0.4 * minf(charge / low_battery, 1.0))


## Host only: a Battery item was used on this flashlight.
func server_recharge() -> void:
	if multiplayer.is_server():
		_recharge.rpc()


@rpc("any_peer", "call_local", "reliable")
func _recharge() -> void:
	if multiplayer.get_remote_sender_id() == 1:
		charge = 1.0
