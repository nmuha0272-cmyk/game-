extends MenuBase
## The team journal (J): every file, tape, photo and personal item anyone
## has found, sorted into tabs. Shared by the whole team.

var _tabs: TabBar
var _list: ItemList
var _text: RichTextLabel
var _empty: Label


func _ready() -> void:
	add_to_group("journal")
	var box := make_panel(Vector2(860, 520))
	make_title(box, "JOURNAL")
	_tabs = TabBar.new()
	for tab_name in Lore.TAB_NAMES:
		_tabs.add_tab(tab_name)
	_tabs.tab_changed.connect(_refresh.unbind(1))
	box.add_child(_tabs)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(260, 0)
	_list.item_selected.connect(_show_selected)
	row.add_child(_list)
	_text = RichTextLabel.new()
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.bbcode_enabled = true
	row.add_child(_text)
	_empty = Label.new()
	_empty.text = "Nothing found yet."
	box.add_child(_empty)
	make_button(box, "Close (J)", close)
	GameState.journal_changed.connect(_refresh)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("journal") and _in_game():
		if visible:
			close()
		elif not GameState.menu_open:
			open()
			_refresh()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## Open the journal straight to one entry (after reading something).
func open_entry(entry_id: String) -> void:
	var entry := Lore.get_entry(entry_id)
	if entry == null:
		return
	if not visible:
		open()
	_tabs.current_tab = entry.type
	_refresh()
	for i in _list.item_count:
		if _list.get_item_metadata(i) == entry_id:
			_list.select(i)
			_show_selected(i)


func _refresh() -> void:
	_list.clear()
	for entry_id in GameState.journal:
		var entry := Lore.get_entry(entry_id)
		if entry and entry.type == _tabs.current_tab:
			var index := _list.add_item(entry.title)
			_list.set_item_metadata(index, entry_id)
	_empty.visible = _list.item_count == 0
	if _list.item_count > 0 and not _list.is_anything_selected():
		_list.select(0)
		_show_selected(0)
	elif _list.item_count == 0:
		_text.text = ""


func _show_selected(index: int) -> void:
	var entry := Lore.get_entry(_list.get_item_metadata(index))
	if entry:
		_text.text = "[b]%s[/b]\n\n%s" % [entry.title, entry.text]
