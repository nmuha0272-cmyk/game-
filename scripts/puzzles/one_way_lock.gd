extends Interactable
class_name OneWayLock

## A lock that only allows specific characters/players through.
## Used for solo splits where one character goes ahead alone.

@export var required_character: int = -1  # Characters.Id, -1 = any
@export var required_item: String = ""    # Item ID required (e.g., "rad_suit")
@export var solo_player_id: int = 0       # Specific player network ID (0 = any)
@export var one_way: bool = true          # If true, locks behind the player
@export var unlock_after: bool = false    # If true, unlocks after solo objective

var _locked: bool = true
var _passed_players: Array[int] = []

func _ready() -> void:
	if not multiplayer.is_server():
		_request_state.rpc_id(1)

func _request_state() -> void:
	if multiplayer.is_server():
		_set_locked.rpc_id(multiplayer.get_remote_sender_id(), _locked)

func can_interact(_by: Player) -> bool:
	return enabled

func get_prompt(by: Player) -> String:
	if !_locked:
		return "[E] Pass through"
	
	if required_character != -1 and by.character != required_character:
		return "Requires %s" % Characters.display_name(required_character)
	if required_item != "" and not by.inventory.has_item(required_item):
		return "Requires %s" % Items.display_name({"id": required_item})
	if solo_player_id != 0 and by.name.to_int() != solo_player_id:
		return "Not your path"
	
	return "[E] Unlock and pass"

func _on_interact(by: Player) -> void:
	if !_locked:
		return
	
	var by_id := by.name.to_int()
	
	if required_character != -1 and by.character != required_character:
		return
	if required_item != "" and not by.inventory.has_item(required_item):
		return
	if solo_player_id != 0 and by_id != solo_player_id:
		return
	
	# Unlock for this player
	_passed_players.append(by_id)
	
	if one_way and _passed_players.size() == 1:
		# Lock behind the first player
		_locked = true
	elif _passed_players.size() >= 2:
		# Multiple players passed, keep unlocked
		_locked = false
	
	if multiplayer.is_server():
		_send_state(by_id)
	else:
		_request_unlock.rpc_id(1, by_id)


@rpc("any_peer", "reliable")
func _request_unlock(player_id: int) -> void:
	if multiplayer.is_server():
		_passed_players.append(player_id)
		if one_way and _passed_players.size() == 1:
			_locked = true
		elif _passed_players.size() >= 2:
			_locked = false
		_send_state(player_id)


func _send_state(player_id: int) -> void:
	_send_locked.rpc_id(player_id, _locked)


@rpc("authority", "call_local", "reliable")
func _send_locked(locked: bool) -> void:
	_locked = locked


func is_locked() -> bool:
	return _locked


func server_restore() -> void:
	# After wipe, restore lock state
	if multiplayer.is_server() and _locked:
		# Already locked
		pass


## Host only: set solo player for this lock (called when solo segment starts)
func server_set_solo_player(player_id: int) -> void:
	if multiplayer.is_server():
		solo_player_id = player_id
		_locked = true
		_send_state(player_id)