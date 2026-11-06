extends RefCounted

# Authored keyframe animation, not an imported unarmed punch.
# All tracks use the real Mixamo skeleton's local rotations, preserving the idle pose.
const CLIP_NAME := "AxeChop"
const CLIP_SECONDS := 2.28 # Played at x3 => 0.76 seconds
const IMPACT_TIME := 0.75 # Played at x3 => impact 0.25 seconds
const KEY_TIMES := [0.0, 0.20, 0.51, 0.75, 1.13, 1.64, CLIP_SECONDS]
const POSE_NAMES := ["rest", "anticipate", "raise", "impact", "follow", "recover", "rest"]

# Radians and directions are local to each Mixamo bone, in degrees below.
# Raise/follow phases are intentionally distinct for shoulder, elbow and spine.
const POSES := {
	"rightshoulder": [
		Vector3.ZERO, Vector3(1, 0, -7), Vector3(-5, -8, -24),
		Vector3(9, 7, 5), Vector3(12, 13, 15), Vector3(2, 0, -4), Vector3.ZERO,
	],
	"rightarm": [
		Vector3.ZERO, Vector3(-10, -7, -12), Vector3(-55, -40, 62),
		Vector3(58, 35, -33), Vector3(72, 34, -46), Vector3(8, 4, -6), Vector3.ZERO,
	],
	"rightforearm": [
		Vector3.ZERO, Vector3(-8, 0, 3), Vector3(-52, 0, -16),
		Vector3(36, 0, 18), Vector3(49, 0, 23), Vector3(8, 0, 5), Vector3.ZERO,
	],
	"righthand": [
		Vector3.ZERO, Vector3(-8, 0, 0), Vector3(-12, 0, -10),
		Vector3(19, 0, 11), Vector3(25, 0, 13), Vector3(5, 0, 2), Vector3.ZERO,
	],
	"leftshoulder": [
		Vector3.ZERO, Vector3(-2, 0, 0), Vector3(-4, 3, -5),
		Vector3(0, -3, 4), Vector3(4, -3, 8), Vector3.ZERO, Vector3.ZERO,
	],
	"leftarm": [
		Vector3.ZERO, Vector3(-5, -5, 7), Vector3(-16, -12, 16),
		Vector3(21, 8, -10), Vector3(19, 9, -8), Vector3(3, 0, 2), Vector3.ZERO,
	],
	"leftforearm": [
		Vector3.ZERO, Vector3(0, 0, 0), Vector3(-15, 0, -7),
		Vector3(12, 0, 5), Vector3(10, 0, 5), Vector3.ZERO, Vector3.ZERO,
	],
	"spine": [
		Vector3.ZERO, Vector3(-2, -6, 2), Vector3(-8, -13, 3),
		Vector3(11, 13, -3), Vector3(13, 15, -4), Vector3(2, 0, 0), Vector3.ZERO,
	],
	"spine1": [
		Vector3.ZERO, Vector3(-3, -8, 1), Vector3(-10, -18, 5),
		Vector3(13, 18, -6), Vector3(16, 19, -8), Vector3(3, 0, 0), Vector3.ZERO,
	],
	"spine2": [
		Vector3.ZERO, Vector3(-2, -6, 0), Vector3(-7, -12, 5),
		Vector3(10, 14, -3), Vector3(13, 18, -5), Vector3(2, 0, 0), Vector3.ZERO,
	],
	"hips": [
		Vector3.ZERO, Vector3(0, -4, 0), Vector3(-3, -9, 1),
		Vector3(4, 9, -2), Vector3(4, 9, -2), Vector3.ZERO, Vector3.ZERO,
	],
}

static func create(skeleton: Skeleton3D, animator: AnimationPlayer, idle_clip_name: String) -> String:
	if skeleton == null or animator == null or idle_clip_name.is_empty():
		return ""
	if not animator.has_animation(idle_clip_name):
		return ""
	var rest_clip: Animation = animator.get_animation(idle_clip_name)
	var target_root: Node = animator.get_node_or_null(animator.root_node)
	if target_root == null:
		return ""
	var skeleton_path := String(target_root.get_path_to(skeleton))
	var clip := Animation.new()
	clip.length = CLIP_SECONDS
	clip.loop_mode = Animation.LOOP_NONE
	clip.step = 0.016
	var pose_tracks := 0
	for bone_index in range(skeleton.get_bone_count()):
		var bone_name := String(skeleton.get_bone_name(bone_index))
		var role := _canonical_bone_name(bone_name)
		var idle_rotation := _sample_idle_rotation(rest_clip, bone_name, skeleton.get_bone_pose_rotation(bone_index))
		var track := clip.add_track(Animation.TYPE_ROTATION_3D)
		clip.track_set_path(track, NodePath(skeleton_path + ":" + bone_name))
		var poses: Array = POSES.get(role, [])
		for sample_index in range(KEY_TIMES.size()):
			var swing_rotation := Quaternion.IDENTITY
			if not poses.is_empty():
				var degrees: Vector3 = poses[sample_index]
				swing_rotation = Quaternion.from_euler(Vector3(deg_to_rad(degrees.x), deg_to_rad(degrees.y), deg_to_rad(degrees.z)))
			clip.rotation_track_insert_key(track, float(KEY_TIMES[sample_index]), idle_rotation * swing_rotation)
		if not poses.is_empty():
			pose_tracks += 1
	# Hips stays in place; imported animations may have nonzero vertical root rest.
	for source_track in range(rest_clip.get_track_count()):
		if rest_clip.track_get_type(source_track) != Animation.TYPE_POSITION_3D:
			continue
		var original_track_path := rest_clip.track_get_path(source_track)
		var track_role := _canonical_bone_name(String(original_track_path.get_concatenated_subnames()))
		if track_role != "hips":
			continue
		var position: Vector3 = rest_clip.position_track_interpolate(source_track, 0.0)
		var frozen_track := clip.add_track(Animation.TYPE_POSITION_3D)
		clip.track_set_path(frozen_track, NodePath(skeleton_path + ":" + String(skeleton.get_bone_name(_bone_index_for_role(skeleton, "hips")))))
		clip.position_track_insert_key(frozen_track, 0.0, position)
		clip.position_track_insert_key(frozen_track, CLIP_SECONDS, position)
		break
	if pose_tracks < 7:
		push_warning("Ashvale: AxeChop arm or spine bones missing from skeleton.")
		return ""
	var library: AnimationLibrary
	if animator.has_animation_library("Ashvale"):
		library = animator.get_animation_library("Ashvale")
	else:
		library = AnimationLibrary.new()
		if animator.add_animation_library("Ashvale", library) != OK:
			return ""
	if library.has_animation(CLIP_NAME):
		library.remove_animation(CLIP_NAME)
	if library.add_animation(CLIP_NAME, clip) != OK:
		return ""
	print("Ashvale animation created: AxeChop (", pose_tracks, " active pose bones, ", CLIP_SECONDS, " clip s, impact at ", IMPACT_TIME, "s)")
	return "Ashvale/" + CLIP_NAME

static func _canonical_bone_name(bone_name: String) -> String:
	var cleaned := bone_name.to_lower().replace(":", "").replace("_", "").replace("-", "").replace(".", "").replace(" ", "")
	if cleaned.begins_with("mixamorig"):
		cleaned = cleaned.trim_prefix("mixamorig")
	return cleaned

static func _bone_index_for_role(skeleton: Skeleton3D, role: String) -> int:
	for bone_index in range(skeleton.get_bone_count()):
		if _canonical_bone_name(String(skeleton.get_bone_name(bone_index))) == role:
			return bone_index
	return -1

static func _sample_idle_rotation(rest_clip: Animation, bone_name: String, fallback: Quaternion) -> Quaternion:
	for track_index in range(rest_clip.get_track_count()):
		if rest_clip.track_get_type(track_index) != Animation.TYPE_ROTATION_3D:
			continue
		var path := rest_clip.track_get_path(track_index)
		if String(path.get_concatenated_subnames()) != bone_name:
			continue
		var sample: Variant = rest_clip.rotation_track_interpolate(track_index, 0.0)
		if sample is Quaternion:
			return sample as Quaternion
	return fallback
