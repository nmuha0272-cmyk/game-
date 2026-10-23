extends Control
## Opening cutscene: newspaper article about 7 missing people near weather station,
## then Eli's flashback to 1999 when his parents died at Deepwell. Plays after character selection.

signal finished

@onready var newspaper_container: CenterContainer = %NewspaperContainer
@onready var flashback_container: CenterContainer = %HospitalContainer
@onready var fade_timer: Timer = $FadeTimer

var _current_phase := 0
var _skip_hold := 0.0
const SKIP_HOLD_TIME := 1.0

# Phase timings
const NEWSPAPER_TIME := 8.0
const FLASHBACK_TIME := 12.0
const FADE_OUT_TIME := 2.0


func _ready() -> void:
	newspaper_container.modulate.a = 0.0
	flashback_container.modulate.a = 0.0
	hide()


func play_cutscene() -> void:
	show()
	await get_tree().create_timer(0.5).timeout
	_start_phase_1()


func _process(delta: float) -> void:
	if not visible:
		return
	# Skip detection: hold Space
	if Input.is_action_pressed("ui_accept"):
		_skip_hold += delta
		if _skip_hold >= SKIP_HOLD_TIME:
			_skip()
	else:
		_skip_hold = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action("ui_accept"):
		get_viewport().set_input_as_handled()


## Phase 1: Newspaper article fades in
func _start_phase_1() -> void:
	_current_phase = 1
	newspaper_container.show()
	_fade_in(newspaper_container, 1.5)
	await get_tree().create_timer(NEWSPAPER_TIME).timeout
	if _current_phase == 1:  # Not skipped
		_fade_out(newspaper_container, 1.0)
		await get_tree().create_timer(1.5).timeout
		if _current_phase == 1:
			_start_phase_2()


## Phase 2: Eli's flashback to 1999
func _start_phase_2() -> void:
	_current_phase = 2
	flashback_container.show()
	_fade_in(flashback_container, 1.5)
	await get_tree().create_timer(FLASHBACK_TIME).timeout
	if _current_phase == 2:  # Not skipped
		_fade_out(flashback_container, FADE_OUT_TIME)
		await get_tree().create_timer(FADE_OUT_TIME + 0.5).timeout
		if _current_phase == 2:
			_finish()


func _skip() -> void:
	_current_phase = 999  # Prevent timers from continuing
	_finish()


func _finish() -> void:
	hide()
	finished.emit()


func _fade_in(target: Control, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(target, "modulate:a", 1.0, duration)


func _fade_out(target: Control, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(target, "modulate:a", 0.0, duration)
