class_name ItemEffects
## What happens when a player uses (left-clicks) the item in their hand.
## Runs on the HOST. Returns true if the item gets used up.
##
## Some items work without clicking: keycards and crowbars are checked by
## doors, gas masks by toxic gas, and fuses / tapes / car batteries will be
## used by machines in Phases 8 and 9.


static func server_use(item: Dictionary, player: Player, target_id: int) -> bool:
	match item.id:
		"battery":
			player.flashlight.server_recharge()
			player.inventory.server_tell("Flashlight recharged.")
			return true
		"medkit":
			var target := Player.find(player.get_tree(), target_id)
			if target and target.is_downed and not target.downed.is_out \
					and target.global_position.distance_to(player.global_position) <= 1.6:
				target.downed.server_set_downed(false)
				return true
			player.inventory.server_tell("Get right next to a downed teammate to use the Med Kit.")
		"flare":
			ItemSpawner.find(player.get_tree()).server_throw_flare(player)
			return true
		"walkie":
			_buzz_other_walkies(player)
		_:
			player.inventory.server_tell(Items.INFO[item.id].hint)
	return false


## Proximity voice chat comes later. For now the walkie-talkie sends a buzz.
static func _buzz_other_walkies(sender: Player) -> void:
	var sender_name := GameState.get_player_name(sender.name.to_int())
	var anyone := false
	for other: Player in sender.get_tree().get_nodes_in_group("players"):
		if other != sender and other.inventory.has_item("walkie"):
			other.inventory.server_tell("Radio: %s is calling you!" % sender_name)
			anyone = true
	sender.inventory.server_tell("Radio: buzzed." if anyone else "Radio: only static...")
