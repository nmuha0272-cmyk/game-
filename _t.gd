extends SceneTree
var main; var tag; var gs
func _initialize(): run()
func t(): return Time.get_ticks_msec()/1000.0
func log_(s): print("[%s t=%.1f] %s" % [tag, t(), s])
func lab(): return main.get_node("Level").get_child(0)
func me(): return Player.find(self, root.multiplayer.get_unique_id())
func other():
	for p in lab().get_node("Players").get_children():
		if p != me(): return p
func ev(action, pressed):
	var e = InputEventAction.new(); e.action = action; e.pressed = pressed; Input.parse_input_event(e)
func at(time):
	while t() < time: await physics_frame
func aim_at(point: Vector3):
	var p = me(); var cam = p.get_node("Head/Camera3D"); var d = point - cam.global_position
	p.rotation.y = atan2(-d.x, -d.z); p.get_node("Head").rotation.x = atan2(d.y, Vector2(d.x, d.z).length())
func go(node: Node3D, dist: float, yoff := 0.0, lateral := 0.0):
	var f = node.global_basis.z; f.y = 0; f = f.normalized()
	var r = Vector3(f.z, 0, -f.x)
	var p = me(); var pos = node.global_position + f * dist + r * lateral; pos.y = 0
	p.global_position = pos; p.velocity = Vector3.ZERO
	# Let physics push us out of anything we landed in, then aim.
	await physics_frame
	await physics_frame
	aim_at(node.global_position + Vector3(0, yoff, 0))
func press(action):
	ev(action, true); await create_timer(0.1).timeout; ev(action, false); await create_timer(0.15).timeout
func prompt():
	var tg = me().get_node("Head/Camera3D/InteractRay").current_target
	return tg.get_prompt(me()) if tg else "-"
func nearest_item(id):
	var best = null
	for n in lab().get_node("Items").get_children():
		if n.has_method("get_prompt") and n.item.id == id and not n.is_queued_for_deletion():
			if best == null or n.global_position.distance_to(me().global_position) < best.global_position.distance_to(me().global_position): best = n
	return best
func bay_state(bay):
	var b = lab().get_node(bay)
	var s = "hall lamp=%s" % b.get_node("HallLamp").is_lit
	if b.has_node("VaultDoor"): s += " vault door open=%s" % b.get_node("VaultDoor").is_open
	return s
func run():
	var a = OS.get_cmdline_user_args(); tag = a[0]
	await process_frame
	gs = root.get_node("GameState")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.get_node("MainMenu/Center/Box/NameEdit").text = a[1]
	var cmds = JSON.parse_string(FileAccess.get_file_as_string(a[2]))
	for c in cmds:
		await at(float(c[0]))
		var L = lab() if main.get_node("Level").get_child_count() > 0 else null
		match c[1]:
			"HOST": main._on_host_requested()
			"JOIN": main._on_join_requested("127.0.0.1")
			"PICK": gs.request_character(int(c[2]))
			"LEVEL": main.get_node("Lobby").level_picker.select(1)
			"START": main._on_start_requested()
			"FREEZE": L.get_node("Monsters/LongMan").set_physics_process(c[2] == 1)
			"GO": await go(L.get_node(c[2]), float(c[3]), float(c[4]) if c.size() > 4 else 0.0, float(c[5]) if c.size() > 5 else 0.0)
			"TP": me().global_position = Vector3(c[2], 0, c[3]); me().velocity = Vector3.ZERO
			"E": await press("interact")
			"Q": await press("ability")
			"HOLDE":
				ev("interact", true); await create_timer(float(c[2])).timeout; ev("interact", false)
			"HOLDQ":
				ev("ability", true); await create_timer(float(c[2])).timeout; ev("ability", false)
			"CROUCH": ev("crouch", c[2] == 1)
			"WALK":
				ev("move_forward", true); await create_timer(float(c[2])).timeout; ev("move_forward", false)
			"FACE": me().rotation.y = deg_to_rad(float(c[2])); me().get_node("Head").rotation.x = 0
			"PICKUP":
				var it = nearest_item(c[2])
				if it:
					var away = me().global_position - it.global_position; away.y = 0
					me().global_position = Vector3(it.global_position.x, 0, it.global_position.z) + away.normalized() * 0.9
					await physics_frame; await physics_frame
					aim_at(it.global_position); await create_timer(0.2).timeout; await press("interact")
				else: log_("no %s!" % c[2])
			"NEAR_OTHER":
				var o = other(); me().global_position = o.global_position + Vector3(1.4, 0, 0.3); aim_at(o.global_position + Vector3(0, 1, 0))
			"AIM_OTHER": aim_at(other().global_position + Vector3(0, 1, 0))
			"GIVE":
				var i = me().inventory.find_item(c[2]); me().inventory.select_slot(i)
				await create_timer(0.2).timeout
				var tm = me().get_node("InventoryControls").get_teammate_in_reach()
				if tm: me().inventory.request_give(tm.name.to_int()) 
				else: log_("give failed: no teammate in reach")
			"TYPE":
				var kp = L.get_node(c[2])
				for i in kp.code_length:
					var key = kp.get_node("Key" + kp.code[i])  # read the code the teammate tells us
					await go(key, 0.55); await create_timer(0.2).timeout; await press("interact")
				await go(kp.get_node("KeyENT"), 0.55); await create_timer(0.2).timeout; await press("interact")
			"TUNE":
				var radio = L.get_node(c[2])
				for i in 25:
					if radio.is_active: break
					var dir = 1 if fposmod(radio.target - radio.frequency, 10.0) <= 5.0 else -1
					await go(radio.get_node("TuneUp" if dir > 0 else "TuneDown"), 0.9); await create_timer(0.15).timeout; await press("interact")
			"DRAG_TO":
				var cab = L.get_node(c[2]); var target = L.get_node(c[3])
				var off = cab.global_position - me().global_position; off.y = 0
				me().global_position = Vector3(target.global_position.x, 0, target.global_position.z) - off
			"BLINKS":
				var light = L.get_node(c[2]); var on = 0
				for i in 40:
					if light.get_node("Light").visible: on += 1
					await create_timer(0.1).timeout
				log_("%s: lamp was lit %d/40 samples over 4s" % [c[3], on])
			"CLICKS":
				var ck = L.get_node("Monsters/LongMan/Click"); var n = 0; var was = false
				for i in 80:
					if ck.playing and not was: n += 1
					was = ck.playing
					await create_timer(0.1).timeout
				log_("monster clicks heard in 8s: %d (no Son in team)" % n)
			"LOG":
				var extra = ""
				if c.size() > 3:
					for path in c[3]:
						var n = L.get_node(path)
						if "is_active" in n: extra += " | %s active=%s" % [path.get_file(), n.is_active]
						elif n is Label3D: extra += " | %s='%s'" % [path.get_file(), n.text.replace("\n", " ")]
						elif n is Node3D and n.has_method("puzzle_set"): extra += " | %s lit=%s" % [path.get_file(), n.get_children().any(func(l): return l is Light3D and l.visible)]
				log_("%s: %s%s | prompt='%s' | msg='%s'" % [c[2], bay_state(c[2].split(":")[0]) if c[2].contains(":") else "", extra, prompt(), me().get_node("HUD/MessageLabel").text])
			"DROP":
				var i = me().inventory.find_item(c[2]); me().inventory.select_slot(i); me().inventory.request_drop()
			"QUIT": quit()
