extends SceneTree

# Atmosfer: Forward+ efektleri acik mi, gunes/ay saate gore dogru mu,
# saat ilerletme ve kamp atesi isigi calisiyor mu.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures := 0
	var method := String(ProjectSettings.get_setting("rendering/renderer/rendering_method"))
	if method != "forward_plus":
		failures += 1
	var game: Node = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	var atmosphere: Node = game.atmosphere
	if atmosphere == null:
		print("AshvaleAtmosphereTest missing atmosphere")
		quit(1)
		return
	atmosphere.time_flows = false
	var env: Environment = atmosphere.environment
	if env.background_mode != Environment.BG_SKY or not env.sdfgi_enabled or not env.ssao_enabled or not env.volumetric_fog_enabled or env.tonemap_mode != Environment.TONE_MAPPER_AGX:
		failures += 1
	var heights := {}
	for hour in [0.0, 6.0, 12.5, 19.0, 23.0]:
		atmosphere.set_hour(hour)
		heights[hour] = atmosphere.sun_direction().y
	if heights[12.5] < 0.7 or heights[0.0] > -0.3 or heights[23.0] > 0.0 or heights[6.0] <= 0.0 or heights[19.0] <= 0.0:
		failures += 1
	atmosphere.set_hour(12.5)
	var noon_sun: float = atmosphere.sun.light_energy
	atmosphere.set_hour(0.5)
	if noon_sun < 1.0 or atmosphere.sun.visible or not atmosphere.moon.visible or not atmosphere.is_night():
		failures += 1
	atmosphere.set_hour(23.5)
	atmosphere.advance_hours(1.0)
	if absf(atmosphere.hour - 0.5) > 0.001 or atmosphere.clock_text() != "00:30":
		failures += 1
	var fire_light: OmniLight3D = game.get_node_or_null("Camp/Campfire/FireLight")
	var flames: GPUParticles3D = game.get_node_or_null("Camp/Campfire/Flames")
	if fire_light == null or flames == null or not fire_light.shadow_enabled:
		failures += 1
	failures += await _first_night(game)
	print("AshvaleAtmosphereTest renderer=", method, " sun_noon_y=", snappedf(heights[12.5], 0.01), " sun_midnight_y=", snappedf(heights[0.0], 0.01), " fire=", fire_light != null, " failures=", failures)
	quit(1 if failures > 0 else 0)

func _check(condition: bool, label: String) -> int:
	if not condition:
		print("First night regression: ", label)
	return 0 if condition else 1

func _first_night(game: Node) -> int:
	var failures := 0
	var fire: Node = game.campfires[0]
	game.atmosphere.set_hour(23.0)
	game.player.position = Vector3(30, 0, 30)
	game.warmth = 1.0
	var before: float = game.health
	game._advance_survival(2)
	failures += _check(game.warmth == 0 and game.health < before, "cold causes damage")
	fire.set_fuel(1.0)
	fire._process(2.0)
	game.player.position = game.CAMP_POSITION
	before = game.health
	game._update_health(1.0)
	failures += _check(not fire.light.visible and not fire.get_node("Flames").emitting and not game.burning and game.health >= before, "extinguished fire is harmless")
	game.player.position += Vector3(2, 0, 0)
	game.inventory.set_count("wood", 1)
	var key := InputEventKey.new()
	key.keycode = KEY_E
	key.pressed = true
	game._unhandled_input(key)
	failures += _check(game.wood == 0 and fire.fuel == fire.WOOD_SECONDS and fire.light.visible, "E relights using one wood")
	game._advance_survival(2)
	failures += _check(game.warmth > 0, "safe warmth near fire")
	game._add_placed_fire(Vector3(-20, 0, 0))
	game.campfires[1].set_fuel(0)
	var path := "user://night-regression.save"
	var data: Dictionary = game.SAVE.capture(game)
	failures += _check(game.SAVE.write_state(data, path), "write midnight save")
	var read: Dictionary = game.SAVE.read_state(path)
	var restored: Node = load("res://main.tscn").instantiate()
	root.add_child(restored)
	restored.set_physics_process(false)
	if read.is_empty():
		failures += _check(false, "read midnight save")
	else:
		game.SAVE.restore(restored, read)
		failures += _check(restored.warmth == game.warmth and restored.campfires[0].fuel == fire.fuel and restored.campfires[1].fuel == 0 and restored.night_started, "restore midnight state")
		restored.atmosphere.set_hour(5.5)
		restored._advance_survival(0)
		failures += _check(restored.survived_first_night, "first dawn")
	game._die()
	game._respawn()
	game.atmosphere.set_hour(5.5)
	game._advance_survival(0)
	failures += _check(not game.survived_first_night, "death before dawn requires another night")
	data.erase("survival")
	game.SAVE.write_state(data, path)
	failures += _check(not game.SAVE.read_state(path).is_empty(), "legacy save opens")
	# A prepared player can reach the first dawn in under ten real minutes.
	var day: Node = load("res://main.tscn").instantiate()
	root.add_child(day)
	day.set_physics_process(false)
	day.player.position = day.CAMP_POSITION + Vector3(2, 0, 0)
	day.inventory.set_count("wood", 3)
	for second in range(530):
		day.atmosphere._process(1.0)
		var camp: Node = day.campfires[0]
		camp._process(1.0)
		if day._night_now() and camp.fuel == 0 and day.wood > 0:
			day._refuel(camp)
		day._advance_survival(1.0)
		day._update_health(1.0)
	failures += _check(day.survived_first_night and not day.is_dead and day.wood == 0, "three logs and a warm camp carry the first night")
	day.queue_free()
	DirAccess.remove_absolute(path)
	restored.queue_free()
	await process_frame
	return failures
