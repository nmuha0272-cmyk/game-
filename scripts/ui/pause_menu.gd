extends MenuBase
## The pause menu (Esc). The game keeps running for everyone else: this is
## online co-op, so nothing can really pause.

signal leave_requested

@export var settings_menu: MenuBase
@export var journal_menu: MenuBase


func _ready() -> void:
	var box := make_panel(Vector2(360, 300))
	make_title(box, "PAUSED")
	make_button(box, "Resume", close)
	make_button(box, "Journal", func() -> void:
		close()
		journal_menu.open()
		journal_menu._refresh())
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


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or not _in_game():
		return
	if visible:
		close()
	elif not GameState.menu_open:
		open()
	get_viewport().set_input_as_handled()


func open() -> void:
	super()
	_reopen_after_settings = true
