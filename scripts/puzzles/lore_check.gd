extends Node
## A puzzle input that is active once the team has found a certain lore
## entry (for example: the elevator override only works after someone has
## read the Containment Order).

signal active_changed(active: bool)

@export var lore_id := ""

var is_active: bool:
	get:
		return lore_id in GameState.journal


func _ready() -> void:
	GameState.journal_changed.connect(func() -> void: active_changed.emit(is_active))
