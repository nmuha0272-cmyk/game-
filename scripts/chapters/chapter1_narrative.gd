extends Node3D
## Chapter 1 narrative initialization. Attach to the chapter root node.
## Creates narrative triggers at the right locations programmatically.

@onready var chapter_root = get_parent()


func _ready() -> void:
	# Only run on the host
	if not multiplayer.is_server():
		return
	
	# Create narrative triggers at key locations
	_create_mentor_intro_trigger()
	_create_stairwell_mentor_trigger()
	_create_eli_leg_injury_trigger()
	_create_eli_rescue_trigger()
	_create_vigil_surveillance_trigger()
	_create_eli_cole_promise_trigger()


func _create_mentor_intro_trigger() -> void:
	# Near the start - Exterior area (near the car)
	var trigger = _make_trigger("MENTOR_INTRO", Vector3(8, 0.5, 15), 6.0)
	chapter_root.add_child(trigger)


func _create_stairwell_mentor_trigger() -> void:
	# In the Hidden Stairwell - after first checkpoint
	var trigger = _make_trigger("MENTOR_STAIRWELL", Vector3(0, -5, -45), 6.0)
	trigger.checkpoint_order = 2
	chapter_root.add_child(trigger)


func _create_eli_leg_injury_trigger() -> void:
	# In the Maintenance Tunnels - near the chase trigger area
	var trigger = _make_trigger("ELI_LEG_INJURY", Vector3(5, -10, -85), 6.0)
	trigger.checkpoint_order = 4
	trigger.requires_character = Characters.Id.SON
	chapter_root.add_child(trigger)


func _create_eli_rescue_trigger() -> void:
	# Elevator Room - after the team helps Eli
	var trigger = _make_trigger("ELI_RESCUE", Vector3(0, -20, -160), 6.0)
	trigger.checkpoint_order = 5
	chapter_root.add_child(trigger)


func _create_vigil_surveillance_trigger() -> void:
	# After rescue, before elevator descends
	var trigger = _make_trigger("VIGIL_SURVEILLANCE", Vector3(0, -20, -170), 6.0)
	trigger.checkpoint_order = 5
	chapter_root.add_child(trigger)


func _create_eli_cole_promise_trigger() -> void:
	# In the elevator, during the descent
	var trigger = _make_trigger("ELI_COLE_PROMISE", Vector3(0, -20, -180), 6.0)
	trigger.checkpoint_order = 6
	chapter_root.add_child(trigger)


func _make_trigger(event_name: String, position: Vector3, radius: float) -> Area3D:
	var trigger = Area3D.new()
	trigger.name = "NarrativeTrigger_" + event_name
	trigger.global_position = position
	
	var collision = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = radius
	collision.shape = sphere
	trigger.add_child(collision)
	
	# Attach the narrative trigger script directly to the Area3D
	var script = preload("res://scripts/chapters/narrative_trigger.gd")
	trigger.set_script(script)
	trigger.trigger_type = event_name
	
	return trigger