extends PuzzleInput
## A slot that takes an item: a fuse box (fuse) or a heavy machine (car
## battery). Hold E to put the item in. The Engineer installs fuses faster.
## Optionally another piece must be active first (for example a breaker
## switch someone else has to hold off).

@export var item_id := "fuse"
@export var insert_time := 4.0
@export var engineer_insert_time := 1.0
## Text on the slot's own label (empty = keep what the scene says).
@export var label_text := ""


func _ready() -> void:
	super()
	var label := get_node_or_null("Label") as Label3D
	if label and label_text != "":
		label.text = label_text


func can_interact(_by: Player) -> bool:
	return enabled and not is_active


func get_hold_time(by: Player) -> float:
	if not _can_insert(by):
		return 0.0
	return engineer_insert_time if by.character == Characters.Id.ENGINEER else insert_time


func get_prompt(by: Player) -> String:
	var item_name: String = Items.INFO[item_id].name
	if not by.inventory.has_item(item_id):
		return "Needs a %s." % item_name
	if not requirement_met():
		return requires_message
	return "[Hold E] Put in the %s" % item_name


func _on_interact(by: Player) -> void:
	if not _can_insert(by):
		by.inventory.server_tell(get_prompt(by))
		return
	by.inventory.server_remove(by.inventory.find_item(item_id))
	server_set_active(true)


func _can_insert(by: Player) -> bool:
	return by.inventory.has_item(item_id) and requirement_met()
