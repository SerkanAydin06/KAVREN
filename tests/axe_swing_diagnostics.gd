extends SceneTree

# Dedicated axe swing must be a real keyframed bone clip (not hand punch FBX).
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
	var rig: Skeleton3D = game.skeleton
	var axe: Node3D = game.equipped_axe
	if anim == null or rig == null or axe == null or game.attack_clip != "Ashvale/AxeChop":
		print("AshvaleAxeSwingTest missing a dedicated equipped weapon or clip")
		quit(1)
		return
	var clip: Animation = anim.get_animation(game.attack_clip)
	if clip == null or clip.loop_mode != Animation.LOOP_NONE:
		failures += 1
	var track_count := 0
	var active_tracks := 0
	for track in range(clip.get_track_count()):
		if clip.track_get_type(track) != Animation.TYPE_ROTATION_3D:
			continue
		track_count += 1
		var full_name := String(clip.track_get_path(track).get_concatenated_subnames()).to_lower()
		if full_name.contains("rightarm") or full_name.contains("rightforearm") or full_name.contains("spine"):
			var a: Quaternion = clip.rotation_track_interpolate(track, 0.0)
			var b: Quaternion = clip.rotation_track_interpolate(track, 0.51)
			var c: Quaternion = clip.rotation_track_interpolate(track, 0.75)
			if absf(a.dot(b)) < 0.98 and absf(b.dot(c)) < 0.97:
				active_tracks += 1
	if track_count < 40 or active_tracks < 3:
		failures += 1
	var clip_duration: float = clip.length / game.ATTACK_PLAYBACK_SPEED
	var impact_seconds: float = game.AXE_CHOP_ANIMATION.IMPACT_TIME / game.ATTACK_PLAYBACK_SPEED
	if absf(impact_seconds - game.CHOP_IMPACT_DELAY) > 0.015 or clip_duration > 0.85 or clip_duration < 0.58:
		failures += 1
	game._start_attack()
	if anim.current_animation != game.attack_clip:
		failures += 1
	if not is_equal_approx(game.attack_remaining, clip_duration):
		failures += 1
	# Three different samples verify that the equipped right-hand bone swings.
	var wrist_index := rig.find_bone("mixamorig_RightHand")
	if wrist_index < 0:
		failures += 1
	else:
		anim.advance(0.02)
		var before_pose: Quaternion = rig.get_bone_pose_rotation(wrist_index)
		anim.advance(0.16)
		var raised_pose: Quaternion = rig.get_bone_pose_rotation(wrist_index)
		anim.advance(0.10)
		var lowered_pose: Quaternion = rig.get_bone_pose_rotation(wrist_index)
		if absf(before_pose.dot(raised_pose)) > 0.999 or absf(raised_pose.dot(lowered_pose)) > 0.999:
			failures += 1
	print("AshvaleAxeSwingTest clip=", game.attack_clip, " tracks=", track_count, " active_tracks=", active_tracks, " seconds=", clip_duration, " impact=", impact_seconds, " failures=", failures)
	quit(1 if failures > 0 else 0)
