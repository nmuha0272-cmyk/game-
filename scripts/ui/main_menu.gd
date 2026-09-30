extends Control
## The title screen. It only shows buttons and tells `main.gd` what was
## pressed. It doesn't do any networking itself.

signal host_requested
signal join_requested(address: String)

@onready var host_button: Button = %HostButton
@onready var join_button: Button = %JoinButton
@onready var quit_button: Button = %QuitButton
@onready var name_edit: LineEdit = %NameEdit
@onready var ip_edit: LineEdit = %IPEdit
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	host_button.pressed.connect(func() -> void: host_requested.emit())
	join_button.pressed.connect(func() -> void: join_requested.emit(ip_edit.text))
	ip_edit.text_submitted.connect(func(text: String) -> void: join_requested.emit(text))
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	show_status("")


func get_player_name() -> String:
	return name_edit.text.strip_edges()


func show_status(text: String) -> void:
	status_label.text = text


func set_buttons_enabled(enabled: bool) -> void:
	host_button.disabled = not enabled
	join_button.disabled = not enabled
	ip_edit.editable = enabled
	name_edit.editable = enabled
