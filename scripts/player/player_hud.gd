extends CanvasLayer
## The on-screen overlay: crosshair, prompts, stamina, ability cooldown,
## progress bar, messages, camera-flash whiteout and the "you are down" screen.
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

var _message_tween: Tween


func _ready() -> void:
	# Other scripts can reach this HUD with get_tree().call_group("player_hud", ...)
	add_to_group("player_hud")
	stamina.changed.connect(_on_stamina_changed)
	_on_stamina_changed(stamina.current, stamina.max_stamina)
	message_label.modulate.a = 0.0
	flash_overlay.modulate.a = 0.0


func _process(_delta: float) -> void:
	var target := interactor.current_target
	prompt_label.visible = target != null and not player.is_downed
	if prompt_label.visible:
		prompt_label.text = target.get_prompt(player)

	var ability: Ability = ability_holder.ability
	if ability:
		var state := "Ready" if ability.is_ready_to_use() else "%ds" % ceili(ability.cooldown_left)
		ability_label.text = "[Q] %s   %s" % [ability.ability_name, state]
		action_bar.visible = ability.progress >= 0.0
		action_bar.value = maxf(ability.progress, 0.0) * 100.0
		status_label.text = ability.status_text
	else:
		ability_label.text = ""

	downed_overlay.visible = player.is_downed
	if player.is_downed:
		status_label.text = "You are down! A teammate can help you up."


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
