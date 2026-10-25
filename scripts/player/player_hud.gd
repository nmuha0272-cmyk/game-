extends CanvasLayer
## The on-screen overlay: crosshair, prompts, stamina, ability cooldown,
## progress bar, gear hotbar (4 quick slots), flashlight battery, messages,
## camera-flash whiteout, toxic gas warning, and the "you are down" screen.
## Only your own player has a HUD.

@export var player: Player
@export var stamina: Stamina
@export var interactor: Interactor
@export var ability_holder: Node

@onready var prompt_label: Label = $Prompt
@onready var stamina_bar: ProgressBar = $StaminaBar
@onready var ability_label: Label = $AbilityLabel
@onready var action_bar: ProgressBar = $ActionBar
@onready var status_label: Label = $StatusLabel
@onready var message_label: Label = $MessageLabel
@onready var flash_overlay: ColorRect = $FlashOverlay
@onready var downed_overlay: ColorRect = $DownedOverlay
@onready var gas_overlay: ColorRect = $GasOverlay
@onready var hotbar: HBoxContainer = $Hotbar
@onready var battery_label: Label = $BatteryLabel
@onready var subtitle_label: Label = $SubtitleLabel
@onready var quick_chat_wheel: Node = $QuickChatWheel
@onready var storage_panel: PanelContainer = $StoragePanel

var _quick_panels: Array[PanelContainer] = []
var _quick_labels: Array[Label] = []
var _storage_slots: Array[PanelContainer] = []
var _storage_labels: Array[Label] = []
var _durability_bar: ProgressBar = null
var _durability_bg: PanelContainer = null
var _storage_grid: GridContainer = null
var _storage_vbox: VBoxContainer = null

var _message_tween: Tween
var _subtitle_left := 0.0


func _ready() -> void:
	add_to_group("player_hud")
	stamina.changed.connect(_on_stamina_changed)
	_on_stamina_changed(stamina.current, stamina.max_stamina)
	message_label.modulate.a = 0.0
	flash_overlay.modulate.a = 0.0
	_build_quick_hotbar()
	_build_storage_panel()
	_build_durability_bar()

	player.get_node("Inventory").changed.connect(_refresh_all)
	_refresh_all()


func _process(_delta: float) -> void:
	var target := interactor.current_target
	var teammate: Player = player.get_node("InventoryControls").get_teammate_in_reach()
	var held := player.inventory.get_active_quick()
	prompt_label.visible = not player.is_downed and (target != null or (teammate != null and not held.is_empty()))
	if target:
		prompt_label.text = target.get_prompt(player)
	elif prompt_label.visible:
		var give_prompt: String = player.get_node("InventoryControls").get_give_prompt()
		if give_prompt != "":
			prompt_label.text = give_prompt
		else:
			prompt_label.text = "[T] Give %s to %s" % [Items.display_name(held),
					GameState.get_player_name(teammate.name.to_int())]

	var charge := player.flashlight.charge
	battery_label.text = "[F] Flashlight  %d%%" % roundi(charge * 100.0)
	battery_label.modulate = Color(1, 0.45, 0.35) if charge < player.flashlight.low_battery else Color.WHITE

	var ability: Ability = ability_holder.ability
	if ability:
		var state := "Ready" if ability.is_ready_to_use() else "%ds" % ceili(ability.cooldown_left)
		ability_label.text = "[Q] %s   %s" % [ability.ability_name, state]
		action_bar.visible = ability.progress >= 0.0
		action_bar.value = maxf(ability.progress, 0.0) * 100.0
		status_label.text = ability.status_text
	else:
		ability_label.text = ""
	if interactor.hold_progress >= 0.0:
		action_bar.visible = true
		action_bar.value = interactor.hold_progress * 100.0

	if status_label.text.is_empty() and HoldSwitch.held_by(player):
		status_label.text = "Holding it up. Stay still!   [E] Let go"
	_show_gas_warning()
	downed_overlay.visible = player.is_downed
	if player.downed.is_out:
		var watching: String = player.get_node("Spectator").watched_name()
		status_label.text = "You bled out. You'll be back at the next checkpoint." + \
				("\nWatching %s (click to switch)" % watching if not watching.is_empty() else "")
	elif player.is_downed:
		status_label.text = "You died... and so did everyone."

	if _subtitle_left > 0.0:
		_subtitle_left -= _delta
		if _subtitle_left <= 0.0:
			subtitle_label.text = ""

	# Quick chat wheel input
	if Input.is_action_just_pressed("quick_chat"):
		quick_chat_wheel.toggle()

	_update_durability_bar()


func _show_gas_warning() -> void:
	var in_gas := false
	for gas in get_tree().get_nodes_in_group("toxic_gas"):
		if gas.contains(player):
			in_gas = true
	gas_overlay.visible = in_gas and not player.is_downed
	if not gas_overlay.visible:
		return
	var mask := player.inventory.find_working_gas_mask()
	if mask[1] >= 0:
		var item := player.inventory.get_quick(mask[1]) if mask[0] else player.inventory.get_storage(mask[1])
		status_label.text = "Toxic gas! Gas mask filter: %ds" % ceili(item.filter)
	else:
		status_label.text = "TOXIC GAS! Get out, or find a gas mask!"


func _build_quick_hotbar() -> void:
	for child in hotbar.get_children():
		hotbar.remove_child(child)
		child.queue_free()
	_quick_panels.clear()
	_quick_labels.clear()

	# Fixed 4 quick slots, wider
	var width := 160
	for i in Inventory.QUICK_SLOTS:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(width, 50)
		panel.add_theme_constant_override("margin_left", 4)
		panel.add_theme_constant_override("margin_right", 4)
		panel.add_theme_constant_override("margin_top", 4)
		panel.add_theme_constant_override("margin_bottom", 4)
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		panel.add_child(vbox)
		var key_label := Label.new()
		key_label.text = "[%d]" % (i + 1)
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_label.add_theme_font_size_override("font_size", 12)
		key_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		vbox.add_child(key_label)
		var item_label := Label.new()
		item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		item_label.clip_text = true
		item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(item_label)
		hotbar.add_child(panel)
		_quick_panels.append(panel)
		_quick_labels.append(item_label)


func _build_storage_panel() -> void:
	storage_panel.visible = false
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	storage_panel.add_child(vbox)

	var title := Label.new()
	title.text = "STORAGE  (Click item, then click quick slot to swap)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	vbox.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(400, 300)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)

	_storage_grid = grid
	_storage_vbox = vbox


func _build_durability_bar() -> void:
	# Created dynamically when melee is equipped
	_durability_bg = PanelContainer.new()
	_durability_bg.custom_minimum_size = Vector2(160, 6)
	_durability_bg.add_theme_constant_override("margin_left", 2)
	_durability_bg.add_theme_constant_override("margin_right", 2)
	_durability_bg.add_theme_constant_override("margin_top", 2)
	_durability_bg.add_theme_constant_override("margin_bottom", 2)
	_durability_bg.visible = false

	_durability_bar = ProgressBar.new()
	_durability_bar.min_value = 0
	_durability_bar.max_value = 100
	_durability_bar.value = 100
	_durability_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_durability_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_durability_bg.add_child(_durability_bar)


func _refresh_all() -> void:
	_refresh_quick_hotbar()
	_refresh_storage_panel()
	_update_durability_bar()


func _refresh_quick_hotbar() -> void:
	var inventory: Inventory = player.get_node("Inventory")
	for i in Inventory.QUICK_SLOTS:
		var item := inventory.get_quick(i)
		var item_name := Items.display_name(item) if not item.is_empty() else "-"
		_quick_labels[i].text = item_name
		var selected := i == inventory.active_quick
		_quick_panels[i].modulate = Color(1, 1, 1, 1) if selected else Color(1, 1, 1, 0.45)


func _refresh_storage_panel() -> void:
	var inventory: Inventory = player.get_node("Inventory")
	var grid: GridContainer = _storage_grid

	# Clear existing
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	for i in inventory.storage_count():
		var item := inventory.get_storage(i)
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(90, 50)
		panel.add_theme_constant_override("margin_left", 4)
		panel.add_theme_constant_override("margin_right", 4)
		panel.add_theme_constant_override("margin_top", 4)
		panel.add_theme_constant_override("margin_bottom", 4)
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		panel.add_child(vbox)

		var item_label := Label.new()
		item_label.text = Items.display_name(item) if not item.is_empty() else "Empty"
		item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_label.clip_text = true
		item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(item_label)

		# Store indices for click handling
		panel.set_meta("storage_idx", i)
		panel.set_meta("is_storage", true)
		panel.gui_input.connect(_on_storage_slot_gui_input.bind(i))

		grid.add_child(panel)


func open_storage_menu() -> void:
	storage_panel.visible = true
	_refresh_storage_panel()


func close_storage_menu() -> void:
	storage_panel.visible = false


func refresh_storage_menu() -> void:
	if storage_panel.visible:
		_refresh_storage_panel()


func _on_storage_slot_gui_input(event: InputEvent, storage_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Clicked a storage item - now wait for quick slot click
		_pending_storage_swap = storage_idx
		# Highlight quick slots to indicate swap mode
		for p in _quick_panels:
			p.add_theme_color_override("panel_color", Color(0.3, 0.5, 0.3, 0.8))


func _gui_input(event: InputEvent) -> void:
	if _pending_storage_swap >= 0 and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Check if clicked on a quick slot
		for i in _quick_panels.size():
			var panel := _quick_panels[i]
			if _is_mouse_over(panel, event.position):
				# Swap!
				player.inventory.request_swap(i, _pending_storage_swap)
				_pending_storage_swap = -1
				for p in _quick_panels:
					p.add_theme_color_override("panel_color", Color(1, 1, 1, 1))
				return
		# Clicked elsewhere - cancel
		_pending_storage_swap = -1
		for p in _quick_panels:
			p.add_theme_color_override("panel_color", Color(1, 1, 1, 1))


func _is_mouse_over(control: Control, mouse_pos: Vector2) -> bool:
	var rect := Rect2(control.global_position, control.size)
	return rect.has_point(mouse_pos)


var _pending_storage_swap := -1


func _update_durability_bar() -> void:
	var inventory: Inventory = player.get_node("Inventory")
	var item := inventory.get_active_quick()
	if item.is_empty() or not item.has("weapon") or not Items.is_melee(item):
		if _durability_bg:
			_durability_bg.visible = false
		return

	var max_dur := float(item.get("max_durability", 100))
	var cur_dur := float(item.get("durability", max_dur))

	# Find the active quick panel and show durability under it
	var active_panel := _quick_panels[inventory.active_quick]
	if not _durability_bg.get_parent():
		active_panel.add_child(_durability_bg)

	_durability_bg.visible = true
	_durability_bar.max_value = max_dur
	_durability_bar.value = cur_dur

	var ratio := cur_dur / maxf(max_dur, 1.0)
	if ratio > 0.5:
		_durability_bar.modulate = Color(0.2, 0.8, 0.2)
	elif ratio > 0.25:
		_durability_bar.modulate = Color(0.9, 0.8, 0.1)
	else:
		_durability_bar.modulate = Color(0.9, 0.2, 0.2)


func show_subtitle_near(where: Vector3, hearing_range: float, speaker: String, text: String,
		seconds: float) -> void:
	if player.global_position.distance_to(where) > hearing_range or not Settings.subtitles:
		return
	subtitle_label.text = ("%s: \"%s\"" % [speaker, text]) if not speaker.is_empty() else text
	_subtitle_left = seconds


func show_message(text: String) -> void:
	message_label.text = text
	if _message_tween:
		_message_tween.kill()
	message_label.modulate.a = 1.0
	_message_tween = create_tween()
	_message_tween.tween_interval(2.5)
	_message_tween.tween_property(message_label, "modulate:a", 0.0, 1.0)


func flash_screen() -> void:
	flash_overlay.modulate.a = 0.8
	create_tween().tween_property(flash_overlay, "modulate:a", 0.0, 0.4)


func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current
	stamina_bar.visible = current < maximum