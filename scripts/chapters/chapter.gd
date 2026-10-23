extends Node3D
## Put on the root of a chapter level. Shows the chapter title when it
## starts and sets chapter rules (like when flashlights start draining).

@export var title := "CHAPTER 1\nTHE SURFACE"
## Flashlights don't drain at the start of the chapter...
@export var flashlight_drain_at_start := false
## ...unless the team restarted from this checkpoint (order) or later.
@export var drain_from_checkpoint := 2

@onready var narrative_manager = preload("res://scripts/chapters/chapter1_narrative.gd").new()
const CHAPTER2_STORY := preload("res://scripts/chapters/chapter2_narrative.gd")


func _ready() -> void:
	# Only the host knows which checkpoint we restarted from, so it decides.
	if not multiplayer.is_server():
		return
	GameState.server_set_flashlight_drain(flashlight_drain_at_start \
			or GameState.checkpoint_order >= drain_from_checkpoint)
	if GameState.checkpoint_order == 0:
		await get_tree().create_timer(1.5).timeout
		_show_title.rpc()
	
	# Initialize narrative triggers for Chapter 1
	if title.begins_with("CHAPTER 1"):
		add_child(narrative_manager)  # (add_child runs its _ready once)
	elif title.begins_with("CHAPTER 2"):
		add_child(CHAPTER2_STORY.new())


@rpc("authority", "call_local", "reliable")
func _show_title() -> void:
	get_tree().call_group("player_hud", "show_message", title.replace("\n", ":  "))
