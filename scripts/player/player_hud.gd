extends CanvasLayer
## The on-screen overlay: crosshair, "[E] ..." prompt and stamina bar.

@export var stamina: Stamina
@export var interactor: Interactor

@onready var prompt_label: Label = $Prompt
@onready var stamina_bar: ProgressBar = $StaminaBar


func _ready() -> void:
	prompt_label.hide()
	stamina.changed.connect(_on_stamina_changed)
	interactor.target_changed.connect(_on_target_changed)
	_on_stamina_changed(stamina.current, stamina.max_stamina)


func _on_target_changed(target: Interactable) -> void:
	if target:
		prompt_label.text = "[E] " + target.prompt_text
		prompt_label.show()
	else:
		prompt_label.hide()


func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current
	# Only show the bar when stamina isn't full.
	stamina_bar.visible = current < maximum
