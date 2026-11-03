extends SceneTree
# Headless diagnostics: prove that clips are linked to the player's skeleton and move bones.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	var player_node: AnimationPlayer = game.animator
	var rig: Skeleton3D = game.skeleton
	if player_node == null or rig == null:
		push_error("AshvaleAnimTest missing AnimationPlayer or Skeleton3D")
		quit(1)
		return
	print("AshvaleAnimTest skeleton=", rig.get_path(), " bones=", rig.get_bone_count(), " animation_root=", player_node.root_node)
	for i in range(mini(rig.get_bone_count(), 10)):
		print("AshvaleAnimTest bone=", rig.get_bone_name(i))
	var animation_root := player_node.get_node_or_null(player_node.root_node)
	if animation_root == null:
		push_error("AshvaleAnimTest missing animation root")
		quit(1)
		return
	print("AshvaleAnimTest walking_fallback=", game.walking_animation_fallback, " walk=", game.walk_clip, " run=", game.run_clip)
	var clips: Array[String] = [game.idle_clip, game.walk_clip, game.run_clip, game.attack_clip]
	var clip_failures := 0
	for clip_name in clips:
		if clip_name.is_empty() or not player_node.has_animation(clip_name):
			print("AshvaleAnimTest MISSING CLIP ", clip_name)
			continue
		var animation: Animation = player_node.get_animation(clip_name)
		var bone_track_count := 0
		var linked_count := 0
		for track_index in range(animation.get_track_count()):
			var track_type := animation.track_get_type(track_index)
			if track_type != Animation.TYPE_ROTATION_3D and track_type != Animation.TYPE_POSITION_3D and track_type != Animation.TYPE_SCALE_3D:
				continue
			bone_track_count += 1
			var track_path := animation.track_get_path(track_index)
			var target_node := animation_root.get_node_or_null(NodePath(String(track_path.get_concatenated_names())))
			if target_node == rig:
				linked_count += 1
			if bone_track_count < 3:
				var key_count := animation.track_get_key_count(track_index)
				var first_key = animation.track_get_key_value(track_index, 0) if key_count > 0 else null
				var last_key = animation.track_get_key_value(track_index, key_count - 1) if key_count > 0 else null
				print("AshvaleAnimTest TRACK ", clip_name, " -> ", track_path, " target=", target_node, " keys=", key_count, " first=", first_key, " last=", last_key)
		player_node.stop()
		player_node.play(clip_name)
		player_node.advance(0.05)
		var poses: Array[Quaternion] = []
		for bone_index in range(rig.get_bone_count()):
			poses.append(rig.get_bone_pose_rotation(bone_index))
		player_node.advance(maxf(0.05, animation.length * 0.45))
		var moved_bones := 0
		for bone_index in range(rig.get_bone_count()):
			if absf(poses[bone_index].dot(rig.get_bone_pose_rotation(bone_index))) < 0.99999:
				moved_bones += 1
		print("AshvaleAnimTest clip=", clip_name, " length=", animation.length, " loop=", animation.loop_mode, " tracks=", bone_track_count, " rig_tracks=", linked_count, " moved_bones=", moved_bones)
		if linked_count < 10 or moved_bones < 3:
			clip_failures += 1
			push_error("AshvaleAnimTest motion not valid: " + clip_name)
	player_node.stop()
	game._update_character_animation(0.016, false, false)
	var idle_state_ok: bool = player_node.current_animation == game.idle_clip
	game._update_character_animation(0.016, true, false)
	var expected_walk: String = game.walk_clip if not game.walk_clip.is_empty() else game.run_clip
	var walking_state_ok: bool = player_node.current_animation == expected_walk
	var walking_speed_ok: bool = absf(player_node.speed_scale - (0.65 if game.walk_clip.is_empty() else 1.0)) < 0.01
	game._update_character_animation(0.016, true, true)
	var running_state_ok: bool = player_node.current_animation == game.run_clip
	var running_speed_ok: bool = absf(player_node.speed_scale - 1.0) < 0.01
	game._start_attack()
	var attack_state_ok: bool = player_node.current_animation == game.attack_clip
	print("AshvaleAnimTest STATES idle=", idle_state_ok, " walking=", walking_state_ok, " walk_speed=", walking_speed_ok, " running=", running_state_ok, " run_speed=", running_speed_ok, " attack=", attack_state_ok)
	if not idle_state_ok or not walking_state_ok or not walking_speed_ok or not running_state_ok or not running_speed_ok or not attack_state_ok:
		clip_failures += 1
	# Root bone yatay konumunu koruyor mu?
	for tested_name in [game.run_clip, game.attack_clip]:
		var tested_animation: Animation = player_node.get_animation(tested_name)
		for index in range(tested_animation.get_track_count()):
			if tested_animation.track_get_type(index) != Animation.TYPE_POSITION_3D:
				continue
			var bone_name := String(tested_animation.track_get_path(index).get_concatenated_subnames()).to_lower()
			if not bone_name.ends_with("hips"):
				continue
			var reference: Vector3 = tested_animation.track_get_key_value(index, 0)
			for key_index in range(tested_animation.track_get_key_count(index)):
				var check: Vector3 = tested_animation.track_get_key_value(index, key_index)
				if absf(check.x - reference.x) > 0.001 or absf(check.z - reference.z) > 0.001:
					clip_failures += 1
	print("AshvaleAnimTest failures=", clip_failures)
	quit(1 if clip_failures > 0 else 0)
