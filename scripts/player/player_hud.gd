extends CanvasLayer
## The on-screen overlay: crosshair, prompts, stamina, ability cooldown,
## progress bar, gear hotbar, flashlight battery, messages, camera-flash
## whiteout, toxic gas warning and the "you are down" screen.
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

var _slot_labels: Array[Label] = []
var _slot_panels: Array[PanelContainer] = []

var _message_tween: Tween
var _subtitle_left := 0.0


func _ready() -> void:
	# Other scripts can reach this HUD with get_tree().call_group("player_hud", ...)
	add_to_group("player_hud")
	stamina.changed.connect(_on_stamina_changed)
	_on_stamina_changed(stamina.current, stamina.max_stamina)
	message_label.modulate.a = 0.0
	flash_overlay.modulate.a = 0.0
	_build_hotbar()
	# (The HUD starts before the player, so look the node up directly.)
	player.get_node("Inventory").changed.connect(_refresh_hotbar)
	_refresh_hotbar()


func _process(_delta: float) -> void:
	var target := interactor.current_target
	var teammate: Player = player.get_node("InventoryControls").get_teammate_in_reach()
	var held := player.inventory.get_active_item()
	prompt_label.visible = not player.is_downed and (target != null or (teammate != null and not held.is_empty()))
	if target:
		prompt_label.text = target.get_prompt(player)
	elif prompt_label.visible:
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
	# Holding E on something (fuse box, darkroom table...) uses the same bar.
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
		status_label.text = "You are down! %ds left. A teammate can help you up (hold E).\nIf time runs out, EVERYONE goes back to the checkpoint!" % \
				ceili(player.downed.time_left)

	if _subtitle_left > 0.0:
		_subtitle_left -= _delta
		if _subtitle_left <= 0.0:
			subtitle_label.text = ""


func _show_gas_warning() -> void:
	var in_gas := false
	for gas in get_tree().get_nodes_in_group("toxic_gas"):
		if gas.contains(player):
			in_gas = true
	gas_overlay.visible = in_gas and not player.is_downed
	if not gas_overlay.visible:
		return
	var mask := player.inventory.find_working_gas_mask()
	if mask >= 0:
		status_label.text = "Toxic gas! Gas mask filter: %ds" % ceili(player.inventory.slots[mask].filter)
	else:
		status_label.text = "TOXIC GAS! Get out, or find a gas mask!"


func _build_hotbar() -> void:
	for i in Inventory.SLOT_COUNT:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(150, 34)
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.clip_text = true
		panel.add_child(label)
		hotbar.add_child(panel)
		_slot_panels.append(panel)
		_slot_labels.append(label)


func _refresh_hotbar() -> void:
	var inventory: Inventory = player.get_node("Inventory")
	for i in Inventory.SLOT_COUNT:
		var item := inventory.get_item(i)
		var item_name := Items.display_name(item) if not item.is_empty() else "-"
		_slot_labels[i].text = "%d  %s" % [i + 1, item_name]
		var selected := i == inventory.active_slot
		_slot_panels[i].modulate = Color(1, 1, 1, 1) if selected else Color(1, 1, 1, 0.45)


## Someone speaks near a spot (a voice line or a tape). Only shown if your
## player is close enough to hear it.
func show_subtitle_near(where: Vector3, hearing_range: float, speaker: String, text: String,
		seconds: float) -> void:
	if player.global_position.distance_to(where) > hearing_range:
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


## A quick white flash, used by the Journalist's camera.
func flash_screen() -> void:
	flash_overlay.modulate.a = 0.8
	create_tween().tween_property(flash_overlay, "modulate:a", 0.0, 0.4)


func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current
	# Only show the bar when stamina isn't full.
	stamina_bar.visible = current < maximum
