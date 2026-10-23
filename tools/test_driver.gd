extends Node
## Automated playtest harness: boots solo, skips the newspaper, waits for the
## intro cutscene, then verifies the opening dialogue cutscene end to end
## (camera, bars, captions, stand-in bodies, acting, line advance, restore),
## plus the third-person view and the inventory pack upgrades.
##
## It stays completely out of the way when you just play the game: it only
## runs when you start the project with `-- --playtest`, e.g.
##     godot --path . -- --playtest
## It quits the game when it is done and writes test_run.log.

var _fails: Array[String] = []
var _done := false
var _log_path := "res://test_run.log"
var _lines: PackedStringArray = []


func _ready() -> void:
	if not OS.get_cmdline_user_args().has("--playtest"):
		return  # ordinary play session: no harness, no auto-quit
	_log("driver ready")
	# Watchdog: always quit, even if a step hangs or a coroutine dies.
	get_tree().create_timer(100.0).timeout.connect(_on_watchdog)
	call_deferred("_run")


func _get_playtest_character() -> int:
	# Check for --character=<name> argument
	var args = OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--character="):
			var char_name = arg.substr(12).to_lower()
			match char_name:
				"eli": return Characters.Id.SON
				"son": return Characters.Id.SON
				"nora": return Characters.Id.JOURNALIST
				"journalist": return Characters.Id.JOURNALIST
				"walter": return Characters.Id.ENGINEER
				"engineer": return Characters.Id.ENGINEER
				"cole": return Characters.Id.GUARD
				"guard": return Characters.Id.GUARD
	# Default: Journalist (for backward compatibility)
	return Characters.Id.JOURNALIST


func _on_watchdog() -> void:
	if _done:
		return
	finish("GLOBAL WATCHDOG TIMEOUT")


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	_log("starting playtest")

	var ok := await _until(func() -> bool: return get_tree().root.get_node_or_null("Main") != null, 10.0)
	if not ok:
		return finish("Main scene never appeared")
	var main: Node = get_tree().root.get_node("Main")
	_log("main scene up at %0.1fs" % ((Time.get_ticks_msec() - t0) / 1000.0))
	await _timer(0.5)

	# --- Solo game with selected character ---
	var playtest_char := _get_playtest_character()
	var char_name := Characters.display_name(playtest_char)
	_log("requesting solo as %s" % char_name)
	main._on_solo_requested()
	await _timer(0.5)
	check(GameState.players.size() == 1, "solo host registered")

	GameState.request_character(playtest_char)
	await _timer(0.5)
	check(GameState.can_start(), "character picked: %s" % char_name)

	_log("starting game")
	GameState.start_game()
	await _timer(0.5)
	check(main.opening_cutscene.visible, "newspaper intro appears after character select")

	ok = await _until(func() -> bool: return main.opening_cutscene._current_phase >= 1, 5.0)
	if not ok:
		return finish("newspaper phase never started")
	_log("newspaper phase 1 up - NOT skipping, letting it play")

	# Wait for cutscene to finish naturally
	ok = await _until(func() -> bool: return not main.opening_cutscene.visible, 30.0)
	if not ok:
		return finish("opening cutscene never finished")
	_log("opening cutscene finished naturally")
	await _timer(0.5)

	# --- Level loads ---
	ok = await _until(func() -> bool: return main.level_root.get_child_count() > 0, 15.0)
	if not ok:
		return finish("level never loaded")
	var level: Node = main.level_root.get_child(0)
	var od: Node = level.get_node("OpeningDialogue")
	_log("level loaded: %s, waiting for dialogue..." % level.name)

	# The pack upgrades have to actually be lying around to be found.
	var spawner: Node = ItemSpawner.find(get_tree())
	var packs := 0
	if spawner:
		for thing in spawner.items_root.get_children():
			var found = thing.get("item")
			if found is Dictionary and str(found.get("id", "")) in ["pouch", "backpack"]:
				packs += 1
	check(packs >= 2, "level has %d pack upgrades to find" % packs)

	# --- Dialogue cutscene triggers (intro ~15s + 2s delay) ---
	ok = await _until(func() -> bool: return od.get("played") or false, 60.0)
	if not ok:
		return finish("dialogue never triggered")
	_log("dialogue triggered at %0.1fs" % ((Time.get_ticks_msec() - t0) / 1000.0))

	# --- Mid-scene state ---
	check(GameState.menu_open, "controls frozen (menu_open) during dialogue")
	check(od._camera != null, "cutscene camera created")
	check(od._bars != null, "letterbox bars created")
	check(od._caption_text != null and od._caption_text.text == od.DIALOGUE[0].text,
			"caption shows line 0: %s" % str(od._caption_text.text if od._caption_text else "?"))
	check(od._caption_name != null and od._caption_name.text.length() > 0,
			"caption shows who speaks: %s" % str(od._caption_name.text if od._caption_name else "?"))

	var players := get_tree().get_nodes_in_group("players")
	check(players.size() == 1, "player spawned (%d found)" % players.size())
	if players.is_empty():
		return finish("no player")
	var p: Node = players[0]

	# Solo: the three characters nobody picked get stand-in bodies.
	check(od._stand_ins.size() == 3, "3 stand-in bodies spawned (%d)" % od._stand_ins.size())
	var stand_ok := true
	for id: int in od._stand_ins:
		var m: Node = od._stand_ins[id].get_node_or_null("Model")
		if m == null:
			stand_ok = false
			continue
		var mr = m.get("_rig")
		if mr == null:
			stand_ok = false
	check(stand_ok, "stand-in bodies have rigged models")

	var plate: Node = p.get_node("Nameplate")
	check(not plate.visible, "own nameplate hidden during scene")

	var body: Node = p.get_node("BodyMesh")
	var meshes := body.find_children("*", "MeshInstance3D", true, false)
	var all_on: bool = meshes.size() > 0
	for m in meshes:
		if m.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			all_on = false
	check(all_on, "own model fully visible, not shadow-only (%d meshes)" % meshes.size())
	check(body.get("acting") == 1.0, "speaker is acting (gesturing)")

	var head: Node3D = p.get_node("Head")
	var d: float = od._camera.global_position.distance_to(head.global_position)
	check(d > 1.0 and d < 5.0, "camera close-up on speaker (dist=%.2f m)" % d)

	# --- Advance all 7 lines with real injected input ---
	for i in range(0, 7):
		var expected: String = od.DIALOGUE[i].text
		if not await _until(func() -> bool:
				return od._caption_text != null and od._caption_text.text == expected, 15.0):
			_log("TIMEOUT: line %d never captioned (current=%s)" % [i,
					str(od._caption_text.text) if od._caption_text else "<none>"])
			break
		await _timer(0.2)
		_press("ui_accept")
		_log("tapped continue after line %d at %0.1fs" % [i, (Time.get_ticks_msec() - t0) / 1000.0])

	# --- Clean end ---
	ok = await _until(func() -> bool: return od._camera == null and not GameState.menu_open, 10.0)
	check(ok, "cutscene ended and controls restored")
	await _timer(0.5)
	check(not GameState.menu_open, "menu_open false after scene")
	check(od._bars == null, "bars freed after scene")
	check(od._caption_text == null, "caption freed after scene")
	check(od._stand_ins.is_empty(), "stand-in bodies freed after scene")
	check(not plate.visible, "own nameplate hidden again after scene")
	check(bool(p.movement_enabled), "movement re-enabled after scene")
	var my_cam: Node3D = p.get_node("Head/Camera3D")
	check(bool(my_cam.current), "player camera active again after scene")
	var body_after: Node = p.get_node("BodyMesh")
	check(body_after.get("acting") == 0.0 and body_after.get("glance") == 0.0,
			"acting/glance cleared after scene")

	# --- Third person (C) ---
	var hud: Node = p.get_node("HUD")
	check(hud.get_node_or_null("NoiseMeter") == null, "no loudness meter on the HUD")
	var persp: Node = p.get_node("Perspective")
	check(persp != null, "perspective node exists")
	check(InputMap.has_action("toggle_view"), "toggle_view is bound (C)")
	check(my_cam.camera_offset == Vector3.ZERO, "camera starts in first person")

	# Does a pressed action actually reach _unhandled_input? (C goes through
	# the same path; the game just refuses it while the mouse isn't captured.)
	var probe := _Probe.new()
	get_tree().root.add_child(probe)
	_press("toggle_view")
	await _timer(0.2)
	check(probe.got, "pressed action reaches _unhandled_input")
	probe.queue_free()

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await _want_third(persp, true)
	check(bool(persp.third_person), "third person turns on")
	check(my_cam.camera_offset != Vector3.ZERO, "camera pulled back over the shoulder")
	check(not bool(my_cam.get_node("HeldItem").visible), "view models hidden in third person")
	var body_on := true
	for m in p.get_node("BodyMesh").find_children("*", "MeshInstance3D", true, false):
		if m.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			body_on = false
	check(body_on, "your own body is drawn in third person")

	await _want_third(persp, false)
	check(not bool(persp.third_person), "third person turns back off")
	check(my_cam.camera_offset == Vector3.ZERO, "camera back at the eye")
	check(bool(my_cam.get_node("HeldItem").visible), "view models back in first person")

	# --- Inventory upgrades: find a pack, wear it, get more storage slots ---
	var inv: Node = p.get_node("Inventory")
	var base_total: int = inv.total_capacity()
	var base_storage: int = inv.storage_count()
	check(base_total == 6, "starts with 6 total slots (4 quick + 2 storage)")
	check(base_storage == 2, "starts with 2 storage slots")
	check(hud._quick_panels.size() == 4, "hotbar always shows 4 quick slots")

	# Wear backpack (+2 storage)
	inv.server_add(Items.create("backpack"))
	var result: Array = inv.find_item("backpack")
	inv.select_quick(result[1])  # select the quick slot it landed in
	inv.request_use(0)
	check(inv.storage_count() == base_storage + 2, "backpack adds 2 storage slots (%d)" % inv.storage_count())
	check(inv.total_capacity() == base_total + 2, "total capacity is 8")
	check(inv.find_item("backpack")[1] == -1, "backpack is used up when worn")

	# Wear pouch (+1 storage)
	inv.server_add(Items.create("pouch"))
	result = inv.find_item("pouch")
	inv.select_quick(result[1])
	inv.request_use(0)
	check(inv.storage_count() == base_storage + 3, "pouch adds 1 storage slot (%d)" % inv.storage_count())
	check(inv.total_capacity() == base_total + 3, "total capacity is 9")
	await _timer(0.2)

	# Fill to max storage
	while inv.storage_count() < Inventory.MAX_STORAGE:
		inv.server_add(Items.create("pouch"))
		result = inv.find_item("pouch")
		inv.select_quick(result[1])
		inv.request_use(0)
	check(inv.storage_count() == Inventory.MAX_STORAGE, "storage caps at %d slots" % Inventory.MAX_STORAGE)
	check(inv.total_capacity() == 4 + Inventory.MAX_STORAGE, "total capacity is 14")

	# Extra pouch kept when storage full
	inv.server_add(Items.create("pouch"))
	var spare_idx: int = inv.find_item("pouch")[1]
	inv.select_quick(spare_idx)
	inv.request_use(0)
	check(inv.storage_count() == Inventory.MAX_STORAGE, "no more storage slots past the cap")
	check(inv.find_item("pouch")[1] == spare_idx, "extra pouch kept when it can't be worn")

	finish()


func check(cond: bool, what: String) -> void:
	if cond:
		_log("PASS: %s" % what)
	else:
		_fails.append(what)
		_log("FAIL: %s" % what)


## Listens for the pressed action so we know events reach _unhandled_input.
class _Probe:
	extends Node
	var got := false

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("toggle_view"):
			got = true


## Press C to flip the view. The game only honours the key while the mouse
## is captured, and a headless run can never capture it, so if the press was
## blocked by that, drive the very same property the input path would set.
func _want_third(persp: Node, wanted: bool) -> void:
	_press("toggle_view")
	await _timer(0.3)
	if bool(persp.third_person) != wanted:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			_log("note: headless mouse mode=%d, driving perspective directly" % Input.mouse_mode)
			persp.third_person = wanted
		await _timer(0.1)


func finish(reason: String = "") -> void:
	if _done:
		return
	_done = true
	if not reason.is_empty():
		_fails.append(reason)
		_log("FAIL: %s" % reason)
	if _fails.is_empty():
		_log("TEST_RESULT: ALL PASS")
	else:
		_log("TEST_RESULT: %d FAILURES: %s" % [_fails.size(), str(_fails)])
	get_tree().quit(0 if _fails.is_empty() else 1)


func _log(msg: String) -> void:
	print("TEST: ", msg)
	_lines.append(msg)
	var f := FileAccess.open(_log_path, FileAccess.WRITE)
	if f:
		for l in _lines:
			f.store_line(l)
		f.close()


func _press(action: String) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)


func _timer(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _until(pred: Callable, timeout: float) -> bool:
	var waited := 0.0
	while waited < timeout:
		if pred.call():
			return true
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	return false
