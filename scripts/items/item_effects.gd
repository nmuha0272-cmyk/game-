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
			_radio_call(player)
		_:
			player.inventory.server_tell(Items.INFO[item.id].hint)
	return false


const RADIO_LINES := [
	"Can anyone hear me? Over.",
	"I found something. Come to me.",
	"Where are you? Over.",
	"It's close... stay quiet.",
	"HELP! It's coming!",
]
## How far away the Long Man hears a walkie-talkie crackle (meters).
const RADIO_NOISE := 16.0


## The walkie-talkie: every click sends the next message to everyone else
## with a walkie, and shows them where you are. But BOTH radios crackle out
## loud, and the Long Man can hear that static...
static func _radio_call(sender: Player) -> void:
	var tree := sender.get_tree()
	var sender_name := GameState.get_player_name(sender.name.to_int())
	var index: int = sender.get_meta("radio_line", 0)
	sender.set_meta("radio_line", index + 1)
	var line: String = RADIO_LINES[index % RADIO_LINES.size()]
	var anyone := false
	for other: Player in tree.get_nodes_in_group("players"):
		if other != sender and other.inventory.has_item("walkie") and not other.is_downed:
			other.inventory.server_radio("Radio, %s: \"%s\"" % [sender_name, line], sender.global_position, sender_name)
			tree.call_group("monsters", "hear_noise", other.global_position, RADIO_NOISE)
			anyone = true
	if anyone:
		sender.inventory.server_radio("You (radio): \"%s\"   (it can hear the static...)" % line, Vector3.INF, "")
	else:
		sender.inventory.server_radio("Radio: only static... nobody else has a walkie-talkie.", Vector3.INF, "")
	tree.call_group("monsters", "hear_noise", sender.global_position, RADIO_NOISE)
