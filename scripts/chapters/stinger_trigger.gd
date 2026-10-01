extends Area3D
## The first time a player walks in: a music sting plays for everyone,
## and optionally a message. Used to build tension between rooms.

@export var message := ""

var _done := false

@onready var _sound: AudioStreamPlayer = $Sound


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if multiplayer.is_server() and not _done and body is Player and not body.is_downed:
		_done = true
		_triggered(body)
		_play.rpc()


## Child scripts can do more here (host only).
func _triggered(_by: Player) -> void:
	pass


@rpc("authority", "call_local", "reliable")
func _play() -> void:
	_done = true
	_sound.play()
	if not message.is_empty():
		get_tree().call_group("player_hud", "show_message", message)
