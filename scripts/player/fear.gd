extends Node
## Fear tracker: the closer a monster is, the more scared you get. Fear
## makes your character model and held weapon shake. Nora (journalist, not
## a soldier) shakes hardest when holding a gun. Eli shakes too but is
## tougher from Army Reserve training.
##
## Only the player's own computer runs this; other players just see you
## move slightly differently.

@export var player: Player

## 0.0 calm .. 1.0 terrified.
var fear := 0.0
## How fast fear decays when nothing scary is happening.
var decay_per_sec := 0.4
## How fast fear rises per second at point-blank range.
var rise_per_sec := 1.0
## Monsters closer than this raise fear at full rate.
var near_distance := 6.0
## Monsters further than this don't raise fear at all.
var far_distance := 20.0

## Eli's Army Reserve training makes him shake less.
var eli_shake_mult := 0.6
## Nora is not trained with weapons - she shakes hardest.
var nora_shake_mult := 1.8

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	# Decay toward calm.
	fear = move_toward(fear, 0.0, decay_per_sec * delta)

	# Rise when a monster is nearby.
	var nearest := _nearest_monster_distance()
	if nearest > 0.0 and nearest < far_distance:
		var t := 1.0 - clampf(nearest / near_distance, 0.0, 1.0)
		fear = move_toward(fear, t, rise_per_sec * delta)

	# Broadcast fear so WeaponHand and character model can shake.
	player.set_meta("fear", fear)


## Distance to the closest monster, or 0.0 if none.
func _nearest_monster_distance() -> float:
	var best: float = 0.0
	for monster in get_tree().get_nodes_in_group("monsters"):
		var d := player.global_position.distance_to(monster.global_position)
		if best == 0.0 or d < best:
			best = d
	return best


## How hard the character should shake right now (0..1).
func character_shake() -> float:
	var base := fear
	if player.character == Characters.Id.SON:
		base *= eli_shake_mult
	elif player.character == Characters.Id.JOURNALIST:
		base *= nora_shake_mult
	return clampf(base, 0.0, 1.0)


## How much extra noise fearful breathing adds (0..1). Monsters hear it.
func noise_multiplier() -> float:
	return 1.0 + fear * 0.5
