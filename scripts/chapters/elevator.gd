extends AnimatableBody3D
## The Chapter 1 ending. Once the dual key consoles have powered it, anyone
## inside can press Descend, but only when the whole team is in the car.
## The car goes down... and then the cable snaps.

## Must be active before the car can go (the dual key console gate).
@export var powered_by: Node
@export var ride_depth := 6.0
@export var fall_depth := 26.0

var _departed := false

@onready var _inside: Area3D = $Inside
@onready var _gate: AnimatableBody3D = $Gate
@onready var _hum: AudioStreamPlayer3D = $Hum
@onready var _snap: AudioStreamPlayer = $Snap
@onready var _lights: Node3D = $Lights
@onready var _panel: Label3D = $Panel


func _ready() -> void:
	$DescendButton.interacted.connect(_on_descend_pressed)


func _process(_delta: float) -> void:
	if not _departed:
		var ready: bool = powered_by != null and powered_by.is_active
		_panel.text = "LEVEL B - SEALED BY ORDER\n%s" % ("OVERRIDE ACCEPTED" if ready else "NO POWER")


## Host only (the Descend button's `interacted` signal fires on the host).
func _on_descend_pressed(by: Player) -> void:
	if _departed:
		return
	if powered_by == null or not powered_by.is_active:
		by.inventory.server_tell("Nothing happens. The elevator needs power and the override.")
		return
	for player: Player in get_tree().get_nodes_in_group("players"):
		if not player.downed.is_out and not _inside.overlaps_body(player):
			by.inventory.server_tell("Everyone needs to be inside the elevator.")
			return
	_depart.rpc()


@rpc("authority", "call_local", "reliable")
func _depart() -> void:
	_departed = true
	_panel.text = "LEVEL B - SEALED BY ORDER\nDESCENDING..."
	create_tween().tween_property(_gate, "position:x", 0.0, 1.5)
	await get_tree().create_timer(1.8).timeout
	_hum.play()
	var ride := create_tween()
	ride.tween_property(self, "position:y", position.y - ride_depth, 6.0)
	await ride.finished
	# Something is wrong. The car shudders...
	_hum.stop()
	for i in 10:
		position.x += randf_range(-0.04, 0.04)
		_lights.visible = i % 2 == 0
		await get_tree().create_timer(0.08).timeout
	_snap.play()
	_lights.visible = false
	var fall := create_tween()
	fall.tween_property(self, "position:y", position.y - fall_depth, 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	get_tree().call_group("screen_fader", "fade_out", "", 0.9)
	await fall.finished
	get_tree().call_group("screen_fader", "fade_out", "CHAPTER 1 COMPLETE\n\nThe Surface", 0.1)
	if multiplayer.is_server():
		await get_tree().create_timer(6.0).timeout
		GameState.server_complete_chapter("Chapter 1 complete. Chapter 2: Power Station is coming soon.")
