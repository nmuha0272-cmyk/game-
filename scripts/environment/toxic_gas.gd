extends Area3D
## A cloud of toxic gas. Players without a working gas mask collapse (are
## downed) after a few seconds inside. A gas mask protects you while its
## filter lasts. The filter only drains while you're in the gas.
## Monsters don't care about the gas.

@export var seconds_until_downed := 4.0

## How long each player has been breathing the gas (network ID -> seconds).
var _exposure := {}


func _ready() -> void:
	add_to_group("toxic_gas")


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	var inside := {}
	for body in get_overlapping_bodies():
		if not body is Player or body.is_downed:
			continue
		var id: int = body.name.to_int()
		inside[id] = true
		var mask: int = body.inventory.find_working_gas_mask()
		if mask >= 0:
			body.inventory.server_drain_filter(mask, delta)
			_exposure[id] = 0.0
		else:
			_exposure[id] = _exposure.get(id, 0.0) + delta
			if _exposure[id] >= seconds_until_downed:
				_exposure[id] = 0.0
				body.downed.server_set_downed(true)
	# Fresh air clears your lungs.
	for id in _exposure.keys():
		if not inside.has(id):
			_exposure.erase(id)


## Used by the HUD on each player's own computer.
func contains(player: Player) -> bool:
	return overlaps_body(player)
