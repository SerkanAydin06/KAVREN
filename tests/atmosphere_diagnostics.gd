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
	print("AshvaleAtmosphereTest renderer=", method, " sun_noon_y=", snappedf(heights[12.5], 0.01), " sun_midnight_y=", snappedf(heights[0.0], 0.01), " fire=", fire_light != null, " failures=", failures)
	quit(1 if failures > 0 else 0)
