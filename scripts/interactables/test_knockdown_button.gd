extends Interactable
## TESTING ONLY: knocks down whoever presses it, so we can test carrying and
## helping up before monsters exist (Phase 6). Remove it from real levels.


func _on_interact(by: Player) -> void:
	by.downed.server_set_downed(true)
