extends MenuBase
## The pause menu (Esc). The game keeps running for everyone else: this is
## online co-op, so nothing can really pause.

signal leave_requested
signal save_requested
signal load_requested

@export var settings_menu: MenuBase
@export var journal_menu: MenuBase


func _ready() -> void:
	var box := make_panel(Vector2(360, 400))
	make_title(box, "PAUSED")
	make_button(box, "Resume", close)
	make_button(box, "Journal", func() -> void:
		close()
		journal_menu.open()
		journal_menu._refresh())
	# Only the host saves and loads (everyone goes back together).
	_save_button = make_button(box, "Save Game  (F5)", func() -> void:
		close()
		save_requested.emit())
	_load_button = make_button(box, "Load Last Save  (F9)", func() -> void:
		close()
		load_requested.emit())
	make_button(box, "Settings", func() -> void:
		hide()
		settings_menu.open())
	make_button(box, "Leave Game", func() -> void:
		close()
		leave_requested.emit())
	make_button(box, "Quit to Desktop", func() -> void: get_tree().quit())
	settings_menu.closed.connect(func() -> void:
		if _in_game() and not GameState.menu_open and _reopen_after_settings:
			_reopen_after_settings = false
			open())


var _reopen_after_settings := false
var _save_button: Button
var _load_button: Button


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or not _in_game():
		return
	if visible:
		close()
	elif not GameState.menu_open:
		open()
	get_viewport().set_input_as_handled()


func open() -> void:
	_save_button.visible = multiplayer.is_server()
	_load_button.visible = multiplayer.is_server() and GameState.has_save()
	super()
	_reopen_after_settings = true
