extends RigidBody3D
## An item lying in the world. Look at it and press E to pick it up.
## The host runs its physics; everyone else just follows its position.

## The item it holds, like {"id": "battery"}. Set by the ItemSpawner.
var item: Dictionary = {}

var _taken := false


func _ready() -> void:
	# Only the host simulates falling and bouncing.
	freeze = not multiplayer.is_server()
	var mesh := Items.make_mesh(item.id)
	add_child(mesh)
	var shape := BoxShape3D.new()
	shape.size = Items.get_bounds(item.id).max(Vector3(0.05, 0.05, 0.05))
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)


# The Interactor calls these, like on doors and switches.
func can_interact(_by: Player) -> bool:
	return not _taken


func get_prompt(by: Player) -> String:
	var text := "[E] Pick up %s" % Items.display_name(item)
	if by.inventory.free_slot() < 0:
		text = "%s  (hands full: drop something with G)" % Items.display_name(item)
	elif Items.is_heavy(item) and by.character != Characters.Id.GUARD:
		text += "  (heavy: you'll move slowly)"
	return text


func interact(by: Player) -> void:
	if multiplayer.is_server():
		_server_pick_up(by)
	else:
		_request_pick_up.rpc_id(1)


@rpc("any_peer", "reliable")
func _request_pick_up() -> void:
	if multiplayer.is_server():
		_server_pick_up(Player.find(get_tree(), multiplayer.get_remote_sender_id()))


func _server_pick_up(by: Player) -> void:
	# _taken stops two players grabbing the same item at the same moment.
	if _taken or by == null or by.is_downed:
		return
	if by.global_position.distance_to(global_position) > 3.5:
		return
	if by.inventory.server_add(item):
		_taken = true
		queue_free()
