extends SceneTree

# Jump.fbx ve Dying Backwards.fbx: kliplerin iskelete baglanmasi, ziplamanin
# klip ile senkron kalkisi, kalca yukselmesinin silinmesi, kamp atesi hasari,
# olum animasyonu, olurken kontrol kilidi ve R ile yeniden dogma.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	var failures := 0
	var anim: AnimationPlayer = game.animator
	if game.jump_clip != "Ashvale/Jump" or game.death_clip != "Ashvale/Death":
		print("AshvaleMoveTest missing clips jump=", game.jump_clip, " death=", game.death_clip)
		quit(1)
		return
	# Kalca hicbir karede ayakta durma yuksekliginin ustune cikmamali.
	var jump_anim: Animation = anim.get_animation(game.jump_clip)
	var lifted := 0
	var crouch_depth := 0.0
	for track in range(jump_anim.get_track_count()):
		if jump_anim.track_get_type(track) != Animation.TYPE_POSITION_3D:
			continue
		if not String(jump_anim.track_get_path(track).get_concatenated_subnames()).to_lower().ends_with("hips"):
			continue
		var standing: Vector3 = jump_anim.track_get_key_value(track, 0)
		for key in range(jump_anim.track_get_key_count(track)):
			var value: Vector3 = jump_anim.track_get_key_value(track, key)
			if value.y > standing.y + 0.0001:
				lifted += 1
			crouch_depth = maxf(crouch_depth, standing.y - value.y)
	if lifted > 0 or crouch_depth <= 0.0:
		failures += 1
	# Ziplama: once comelme, gecikmeden sonra fiziksel kalkis.
	game._begin_jump()
	if game.jump_phase != "crouch" or anim.current_animation != game.jump_clip:
		failures += 1
	var start_pos: float = anim.current_animation_position
	game._advance_jump(game.JUMP_TAKEOFF_DELAY * 0.5)
	if game.player.velocity.y > 1.0:
		failures += 1
	game._advance_jump(game.JUMP_TAKEOFF_DELAY * 0.6)
	if game.jump_phase != "air" or not is_equal_approx(game.player.velocity.y, game.JUMP_VELOCITY):
		failures += 1
	var air_seconds: float = 2.0 * game.JUMP_VELOCITY / game.GRAVITY
	var clip_air: float = (game.JUMP_CLIP_LANDING - game.JUMP_CLIP_TAKEOFF) / game.JUMP_PLAYBACK_SPEED
	if absf(air_seconds - clip_air) > 0.01 or absf(start_pos - game.JUMP_CLIP_START) > 0.02:
		failures += 1
	# Ziplarken balta savrulmaz.
	game.attack_remaining = 0.0
	game._start_attack()
	if game.attack_remaining > 0.0:
		failures += 1
	game.jump_phase = ""
	game.player.velocity = Vector3.ZERO
	# Kamp atesi: atesin icinde can azalir, sifirda olum.
	game.player.global_position = game.CAMP_POSITION + Vector3(0.2, 0.1, 0)
	game._update_health(0.5)
	var burned: float = game.health
	if not game.burning or burned >= game.MAX_HEALTH:
		failures += 1
	for i in range(20):
		game._update_health(0.25)
	if not game.is_dead or anim.current_animation != game.death_clip:
		failures += 1
	anim.advance(2.5)
	var died_state: String = game.current_animation_state
	# Olu iken saldiri ve ziplama calismaz.
	game._start_attack()
	game._update_character_animation(0.1, true, false)
	if game.attack_remaining > 0.0 or anim.current_animation != game.death_clip or died_state != "Death":
		failures += 1
	game._respawn()
	if game.is_dead or game.health != game.MAX_HEALTH or game.player.global_position.distance_to(game.SPAWN_POSITION) > 0.01 or anim.current_animation != game.idle_clip:
		failures += 1
	print("AshvaleMoveTest jump_speed=", snappedf(game.JUMP_PLAYBACK_SPEED, 0.001), " takeoff_delay=", snappedf(game.JUMP_TAKEOFF_DELAY, 0.001), " crouch=", snappedf(crouch_depth, 0.001), " burned_hp=", snappedf(burned, 0.1), " failures=", failures)
	quit(1 if failures > 0 else 0)
