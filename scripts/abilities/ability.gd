class_name Ability
extends Node
## Base script shared by all four character abilities.
## It handles the ability key (Q) and the cooldown timer, so each ability
## only has to say what happens in `_on_pressed` / `_on_released`.

## Name shown on the HUD, e.g. "Sense".
var ability_name := "Ability"
## Seconds to wait after using the ability before it can be used again.
var cooldown := 0.0
var cooldown_left := 0.0
## Short text the HUD shows while the ability is busy ("Holding the door").
var status_text := ""
## 0..1 for abilities you hold until finished (Repair). -1 hides the bar.
var progress := -1.0

var player: Player
var interactor: Interactor


## Called by the AbilityHolder right before the ability is added.
func setup(owner_player: Player) -> void:
	player = owner_player
	interactor = player.get_node("Head/Camera3D/InteractRay")


## True on the computer of the person playing this character.
func is_local() -> bool:
	return player.is_multiplayer_authority()


func is_ready_to_use() -> bool:
	return cooldown_left <= 0.0


func start_cooldown() -> void:
	cooldown_left = cooldown


## Network ID of the person playing this character.
func owner_id() -> int:
	return player.name.to_int()


func _process(delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not is_local() or player.is_downed or GameState.menu_open:
		return
	if event.is_action_pressed("ability"):
		_on_pressed()
	elif event.is_action_released("ability"):
		_on_released()


## Child scripts replace these.
func _on_pressed() -> void:
	pass


func _on_released() -> void:
	pass
