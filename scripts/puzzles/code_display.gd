extends Label3D
## Shows a code from a keypad or radio, like a monitor, a chart or a photo.
## With hidden_until set, it shows "???" until that piece is active
## (for example until the Journalist develops the photo).

@export var source: Node
@export_multiline var template := "CODE: %s"
@export var hidden_until: Node
## What it shows while hidden.
@export var hidden_text := "???"


func _ready() -> void:
	source.code_changed.connect(_refresh.unbind(1))
	if hidden_until:
		hidden_until.active_changed.connect(_refresh.unbind(1))
	_refresh()


func _refresh() -> void:
	var value: String = source.get_display_code()
	# Solo test mode: the code shows straight away, no tape/power hunt.
	if hidden_until and not hidden_until.is_active and not GameState.is_solo():
		value = hidden_text
	text = template % value
