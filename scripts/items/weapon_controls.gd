extends Node
## Your keys for the gun: 4 draws / holsters it, left click fires it while it
## is out, R reloads. Only does anything on your own player.

@export var weapon: WeaponHolder


func _unhandled_input(event: InputEvent) -> void:
	if not weapon.player.is_multiplayer_authority() or weapon.player.is_downed:
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event.is_action_pressed("weapon_toggle"):
		weapon.request_toggle()
	elif event.is_action_pressed("reload"):
		weapon.request_reload()
	elif event.is_action_pressed("drop_weapon"):
		weapon.request_drop()
	elif event.is_action_pressed("use_item") and weapon.drawn:
		weapon.request_fire()


# Full-auto weapons keep firing while the button is held.
func _process(_delta: float) -> void:
	if not weapon.player.is_multiplayer_authority() or weapon.player.is_downed:
		return
	if not weapon.drawn or not weapon.has_weapon():
		return
	if not weapon.info().get("auto", false):
		return
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_action_pressed("use_item"):
		weapon.request_fire()
