extends Node
class_name EliColeBond

var bond_level: int = 1
var _narrative_triggered: Dictionary = {}

func _ready() -> void:
	# Load bond level from checkpoint if available
	if GameState.checkpoint_inventories.has("eli_cole_bond_level"):
		bond_level = GameState.checkpoint_inventories["eli_cole_bond_level"]

func unlock_next_level(chapter: int) -> void:
	var new_level = chapter - 1  # Ch 2->1, Ch 3->2, etc.
	if new_level > bond_level:
		bond_level = new_level
		_save_bond_level()
		_trigger_narrative(chapter)

func _save_bond_level() -> void:
	if multiplayer.is_server():
		GameState.checkpoint_inventories["eli_cole_bond_level"] = bond_level

static func _is_eli_cole_pair(p1: Player, p2: Player) -> bool:
	var c1 = p1.character
	var c2 = p2.character
	return (c1 == Characters.Id.SON and c2 == Characters.Id.GUARD) or \
	       (c1 == Characters.Id.GUARD and c2 == Characters.Id.SON)

func on_give_item(giver: Player, receiver: Player) -> Dictionary:
	if _is_eli_cole_pair(giver, receiver):
		return {"bonus": true, "extra_magazine": true, "message": "Bond bonus! +1 magazine"}
	return {"bonus": false}

func on_sync_walk_request(p1: Player, p2: Player) -> bool:
	if _is_eli_cole_pair(p1, p2) and bond_level >= 2:
		return true
	return false

func on_dual_hold(p1: Player, p2: Player) -> float:
	if _is_eli_cole_pair(p1, p2) and bond_level >= 3:
		return 1.5
	return 1.0

func on_revive(reviver: Player, downed: Player) -> float:
	if _is_eli_cole_pair(reviver, downed) and bond_level >= 4:
		return 0.5  # 15s instead of 30s
	return 1.0

func on_cover_fire(p1: Player, p2: Player) -> bool:
	if _is_eli_cole_pair(p1, p2) and bond_level >= 5:
		return true
	return false

func _trigger_narrative(chapter: int) -> void:
	if _narrative_triggered.has(chapter):
		return
	_narrative_triggered[chapter] = true
	
	var lines = {
		2: "Cole quietly hands Eli an extra magazine. \"Save it for later.\"",
		3: "Cole hesitates at the seal door. Eli notices. \"You okay?\" Cole: \"Just... memories.\"",
		4: "Walter revealed. Cole steps in front of Eli. \"Not him. Not again.\"",
		5: "Safe room. Cole admits: \"Your mother died saving your father. And I let it happen.\"",
		6: "Final choice. Cole's VIGIL orders vs his promise to Eli. Eli decides."
	}
	
	if lines.has(chapter):
		GameState.server_announce.rpc(lines[chapter])

func get_bond_level() -> int:
	return bond_level

func reset() -> void:
	bond_level = 1
	_narrative_triggered.clear()
	_save_bond_level()