extends Node3D

const FALLBACK_MODEL_PATH := "res://assets/characters/base_adventurer_running.glb"
const CHAR1_IDLE_PATH := "res://assets/characters/Char1/Idle.fbx"
const CHAR1_WALK_ANIMATION_PATH := "res://assets/characters/Char1/Walking_Animated.fbx"
const CHAR1_RUNNING_PATH := "res://assets/characters/Char1/Running.fbx"
const CHAR1_ATTACK_PATH := "res://assets/characters/Char1/Standing Melee Attack Downward.fbx"
const PRIORITY_CHARACTER_FILES := [
	"res://assets/characters/Char1/Walking.fbx",
	"res://assets/characters/char1.glb",
	"res://assets/characters/char1.gltf",
	"res://assets/characters/char1.fbx",
	"res://assets/characters/char1.tscn",
	"res://char1.glb",
	"res://char1.gltf",
	"res://char1.fbx",
	"res://char1.tscn",
]
# Inspector'da bir model seçilirse, otomatik aramadan önce o kullanılır.
@export_file("*.glb", "*.gltf", "*.fbx", "*.tscn") var character_file: String = ""
# Meshy modelleri farkli ileri bakis yonlerinde olabilir.
@export_range(-180.0, 180.0, 1.0) var character_facing_offset := 0.0
const WALK_SPEED := 4.0
const RUN_SPEED := 7.0
const MODEL_HEIGHT := 1.8
const GRAVITY := 18.0

var player: CharacterBody3D
var visuals: Node3D
var camera_pivot: Node3D
var animator: AnimationPlayer
var skeleton: Skeleton3D
var run_clip := ""
var walk_clip := ""
var idle_clip := ""
var jump_clip := ""
var fall_clip := ""
var attack_clip := ""
var attack_remaining := 0.0
var loaded_character_path := ""
var character_animation_status := "bekleniyor"
var current_animation_state := "Bekliyor"
var walking_animation_fallback := false
var motion_time := 0.0
var bone_map: Dictionary = {}
var neutral_bone_pose: Dictionary = {}
var yaw := 0.0
var pitch := -0.18
var hud: Label
var resource_nodes: Array[Node3D] = []
var wood := 0
var stone := 0
var stamina := 100.0
var camera_distance := 5.0

func _ready() -> void:
	_make_world()
	_make_player()
	_make_camera()
	_make_camp()
	_make_hud()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _make_world() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.46, 0.57, 0.64)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.85, 0.8)
	env_node.environment = env
	add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	add_child(sun)
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	add_child(ground)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(80, 0.4, 80)
	mesh.mesh = box
	mesh.position.y = -0.2
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.39, 0.27)
	mesh.material_override = mat
	ground.add_child(mesh)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(80, 0.4, 80)
	collider.shape = shape
	collider.position.y = -0.2
	ground.add_child(collider)

func _add_primitive(parent: Node3D, shape_mesh: Mesh, pos: Vector3, tint: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = shape_mesh
	item.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	item.material_override = material
	parent.add_child(item)
	return item

func _make_camp() -> void:
	# Lightweight test environment suitable for Compatibility renderer.
	for i in range(16):
		var angle := float(i) * TAU / 16.0
		var distance := 9.0 + float(i % 4) * 3.5
		var pos := Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
		var tree := Node3D.new()
		tree.name = "Tree_%02d" % i
		tree.position = pos
		add_child(tree)
		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.22
		trunk.bottom_radius = 0.33
		trunk.height = 2.4
		_add_primitive(tree, trunk, Vector3(0, 1.2, 0), Color(0.36, 0.23, 0.13))
		var tree_body := StaticBody3D.new()
		tree_body.name = "TrunkBody"
		tree.add_child(tree_body)
		var tree_collision := CollisionShape3D.new()
		var trunk_shape := CylinderShape3D.new()
		trunk_shape.radius = 0.29
		trunk_shape.height = 2.4
		tree_collision.shape = trunk_shape
		tree_collision.position.y = 1.2
		tree_body.add_child(tree_collision)
		var crown := SphereMesh.new()
		crown.radius = 1.35
		crown.height = 2.5
		_add_primitive(tree, crown, Vector3(0, 3.1, 0), Color(0.15, 0.34 + 0.02 * (i % 3), 0.17))
		tree.set_meta("resource_type", "wood")
		resource_nodes.append(tree)
	for i in range(12):
		var angle := float(i) * TAU / 12.0 + 0.23
		var distance := 5.5 + float(i % 3) * 4.0
		var rock := Node3D.new()
		rock.name = "Rock_%02d" % i
		rock.position = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		add_child(rock)
		var rock_mesh := SphereMesh.new()
		rock_mesh.radius = 0.65
		rock_mesh.height = 0.9
		_add_primitive(rock, rock_mesh, Vector3(0, 0.35, 0), Color(0.40, 0.43, 0.43))
		var rock_body := StaticBody3D.new()
		rock_body.name = "RockBody"
		rock.add_child(rock_body)
		var rock_collision := CollisionShape3D.new()
		var rock_shape := SphereShape3D.new()
		rock_shape.radius = 0.62
		rock_collision.shape = rock_shape
		rock_collision.position.y = 0.35
		rock_body.add_child(rock_collision)
		rock.set_meta("resource_type", "stone")
		resource_nodes.append(rock)
	var camp := Node3D.new()
	camp.name = "Camp"
	camp.position = Vector3(3, 0, 2)
	add_child(camp)
	var pit := CylinderMesh.new()
	pit.top_radius = 0.85
	pit.bottom_radius = 0.85
	pit.height = 0.2
	_add_primitive(camp, pit, Vector3(0, 0.1, 0), Color(0.22, 0.2, 0.19))
	var ember := SphereMesh.new()
	ember.radius = 0.4
	ember.height = 0.4
	_add_primitive(camp, ember, Vector3(0, 0.25, 0), Color(0.98, 0.41, 0.09))

func _make_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "GameHUD"
	add_child(layer)
	var ui_root := Control.new()
	ui_root.name = "HUDRoot"
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui_root)

	var panel := PanelContainer.new()
	panel.name = "ResourcePanel"
	panel.position = Vector2(32, 32)
	panel.custom_minimum_size = Vector2(470, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.04, 0.05, 0.84)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	ui_root.add_child(panel)

	hud = Label.new()
	hud.name = "ResourceInfo"
	hud.add_theme_font_size_override("font_size", 27)
	hud.add_theme_color_override("font_color", Color.WHITE)
	hud.add_theme_color_override("font_shadow_color", Color.BLACK)
	hud.add_theme_constant_override("shadow_offset_x", 1)
	hud.add_theme_constant_override("shadow_offset_y", 2)
	panel.add_child(hud)

	var controls := Label.new()
	controls.name = "Controls"
	controls.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	controls.offset_left = 32
	controls.offset_right = 1240
	controls.offset_top = -90
	controls.offset_bottom = -32
	controls.add_theme_font_size_override("font_size", 24)
	controls.add_theme_color_override("font_color", Color(0.94, 0.96, 0.96))
	controls.add_theme_color_override("font_shadow_color", Color.BLACK)
	controls.add_theme_constant_override("shadow_offset_x", 2)
	controls.add_theme_constant_override("shadow_offset_y", 2)
	controls.text = "WASD  Hareket    SHIFT  Koş    SPACE  Zıpla    E  Topla\nFARE  Kamera / Zoom    SOL TIK  Saldırı    ESC  İmleç    F11  Tam Ekran"
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(controls)
	_update_hud()

func _update_hud() -> void:
	var nearby := _nearest_resource()
	var hint := ""
	if nearby != null:
		hint = "\n[E] %s topla" % ("ODUN" if String(nearby.get_meta("resource_type")) == "wood" else "TAŞ")
	hud.text = "ASHVALE  •  KEŞİF\nODUN  %d     TAŞ  %d\nDAYANIKLILIK  %d%%%s\nKARAKTER  %s  |  %s\nANİMASYON  %s" % [wood, stone, int(stamina), hint, loaded_character_path.get_file().get_basename() if not loaded_character_path.is_empty() else "yok", character_animation_status, current_animation_state]

func _nearest_resource() -> Node3D:
	var best: Node3D = null
	var best_distance := 3.0
	for node in resource_nodes:
		if not is_instance_valid(node):
			continue
		var distance := player.global_position.distance_to(node.global_position)
		if distance < best_distance:
			best_distance = distance
			best = node
	return best

func _collect_resource() -> void:
	var target := _nearest_resource()
	if target == null:
		return
	if String(target.get_meta("resource_type")) == "wood":
		wood += 1
	else:
		stone += 1
	resource_nodes.erase(target)
	target.queue_free()
	_update_hud()

func _make_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 0.1, 0)
	add_child(player)
	var col := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	col.shape = capsule
	col.position.y = 0.9
	player.add_child(col)
	visuals = Node3D.new()
	visuals.name = "Visuals"
	player.add_child(visuals)

	var character: Node3D = null
	for path in _character_candidates():
		if not ResourceLoader.exists(path):
			continue
		var file := load(path)
		if not file is PackedScene:
			continue
		var instance := (file as PackedScene).instantiate()
		if instance is Node3D:
			character = instance as Node3D
			loaded_character_path = path
			break
		instance.queue_free()
	if character == null:
		push_warning("Ashvale: char1 veya yedek GLB bulunamadi; test kapsulu gosteriliyor.")
		var body := MeshInstance3D.new()
		var fallback := CapsuleMesh.new()
		fallback.radius = 0.35
		fallback.height = 1.8
		body.mesh = fallback
		body.position.y = 0.9
		visuals.add_child(body)
		character_animation_status = "Model yok"
		return

	character.name = "CharacterModel"
	visuals.add_child(character)
	var bounds := _measure_model_bounds(character)
	if bounds.size.y > 0.01:
		var factor := clampf(MODEL_HEIGHT / bounds.size.y, 0.01, 20.0)
		character.scale = Vector3.ONE * factor
		character.position.y = -bounds.position.y * factor

	animator = _find_animator(character)
	skeleton = _find_skeleton(character)
	if animator != null:
		for clip in animator.get_animation_list():
			var clip_name := String(clip)
			var lower := clip_name.to_lower()
			if idle_clip.is_empty() and ("idle" in lower or "breath" in lower):
				idle_clip = clip_name
			elif walk_clip.is_empty() and ("walk" in lower or "walking" in lower):
				walk_clip = clip_name
			elif run_clip.is_empty() and ("run" in lower or "sprint" in lower):
				run_clip = clip_name
			elif jump_clip.is_empty() and ("jump" in lower or "hop" in lower):
				jump_clip = clip_name
			elif fall_clip.is_empty() and ("fall" in lower or "airborne" in lower):
				fall_clip = clip_name
		if not idle_clip.is_empty():
			animator.play(idle_clip)
		else:
			animator.stop()

	# Char1 Mixamo FBX dosyalarindaki ortak iskeleti kullanarak klipleri birlestir.
	# Walking.fbx dokulu modeldir; Idle/Running/Attack sadece animasyon tasir.
	if loaded_character_path.to_lower().contains("/char1/") and animator != null and skeleton != null:
		if loaded_character_path.to_lower().ends_with("/walking.fbx") and walk_clip.is_empty():
			walk_clip = _first_non_reset_clip(animator)
		var imported_idle := _import_external_clip(CHAR1_IDLE_PATH, "Idle", true)
		var imported_walk := _import_external_clip(CHAR1_WALK_ANIMATION_PATH, "Walk", true)
		var imported_run := _import_external_clip(CHAR1_RUNNING_PATH, "Run", true)
		var imported_attack := _import_external_clip(CHAR1_ATTACK_PATH, "Attack", false)
		if not imported_idle.is_empty():
			idle_clip = imported_idle
		if not imported_walk.is_empty():
			walk_clip = imported_walk
		if not imported_run.is_empty():
			run_clip = imported_run
		if not imported_attack.is_empty():
			attack_clip = imported_attack
		# Mixamo kliplerinde root bone ileri dogru hareket edebilir.
		# CharacterBody3D zaten hareket ettigi icin yatay root motion cikarilir.
		for selected_clip in [idle_clip, walk_clip, run_clip, attack_clip]:
			if not selected_clip.is_empty():
				_remove_horizontal_root_motion(animator.get_animation(selected_clip))
		if not walk_clip.is_empty():
			var walk_animation: Animation = animator.get_animation(walk_clip)
			if _clip_has_joint_motion(walk_animation):
				walk_animation.loop_mode = Animation.LOOP_LINEAR
			else:
				# Mevcut Walking.fbx sadece tek karelik sabit poz tasiyor.
				walking_animation_fallback = true
				walk_clip = ""
				push_warning("Ashvale: Walking.fbx sabit poz (animasyon yok). Gercek yuruyus FBX yuklenene kadar Running klibi yavas kullanilacak.")
		if not idle_clip.is_empty():
			animator.play(idle_clip)
	if skeleton != null and skeleton.get_bone_count() > 0:
		_cache_bone_map()
		character_animation_status = "Klipler (Walk yedek)" if walking_animation_fallback else ("Klipler" if not run_clip.is_empty() or not walk_clip.is_empty() else "Basit rig hareketi")
	else:
		character_animation_status = "Rig yok"
		push_warning("Ashvale: secilen karakterde Skeleton3D bulunamadi. Kol/bacak animasyonu icin rig gerekli.")
	print("Ashvale character: ", loaded_character_path, " | skeleton: ", skeleton != null, " | clips: ", idle_clip, "/", walk_clip, "/", run_clip, "/", jump_clip, "/", attack_clip)



func _clip_has_joint_motion(animation: Animation) -> bool:
	if animation == null:
		return false
	for track_index in range(animation.get_track_count()):
		if animation.track_get_type(track_index) != Animation.TYPE_ROTATION_3D:
			continue
		var key_count := animation.track_get_key_count(track_index)
		if key_count < 2:
			continue
		var first_rotation: Quaternion = animation.track_get_key_value(track_index, 0)
		for key_index in range(1, key_count):
			var other_rotation: Quaternion = animation.track_get_key_value(track_index, key_index)
			if absf(first_rotation.dot(other_rotation)) < 0.9995:
				return true
	return false


func _remove_horizontal_root_motion(animation: Animation) -> void:
	if animation == null:
		return
	for track_index in range(animation.get_track_count()):
		if animation.track_get_type(track_index) != Animation.TYPE_POSITION_3D:
			continue
		var track_path := animation.track_get_path(track_index)
		var bone_name := String(track_path.get_concatenated_subnames()).to_lower()
		if not bone_name.ends_with("hips") and not bone_name.ends_with("hip"):
			continue
		var count := animation.track_get_key_count(track_index)
		if count == 0:
			continue
		var initial_position: Vector3 = animation.track_get_key_value(track_index, 0)
		for key_index in range(count):
			var position: Vector3 = animation.track_get_key_value(track_index, key_index)
			position.x = initial_position.x
			position.z = initial_position.z
			animation.track_set_key_value(track_index, key_index, position)


func _first_non_reset_clip(player_node: AnimationPlayer) -> String:
	for animation_name in player_node.get_animation_list():
		var clip := String(animation_name)
		if "reset" not in clip.to_lower():
			return clip
	return ""


func _import_external_clip(fbx_path: String, target_name: String, should_loop: bool) -> String:
	if animator == null or skeleton == null or not ResourceLoader.exists(fbx_path):
		return ""
	var resource := load(fbx_path)
	if not resource is PackedScene:
		return ""
	var source_instance := (resource as PackedScene).instantiate()
	var source_player := _find_animator(source_instance)
	if source_player == null:
		source_instance.queue_free()
		return ""
	var clip_name := _first_non_reset_clip(source_player)
	if clip_name.is_empty():
		source_instance.queue_free()
		return ""
	var original := source_player.get_animation(clip_name)
	if original == null:
		source_instance.queue_free()
		return ""
	var animation := original.duplicate(true) as Animation
	var source_root := source_player.get_node_or_null(source_player.root_node)
	var target_root := animator.get_node_or_null(animator.root_node)
	if source_root == null or target_root == null:
		source_instance.queue_free()
		return ""
	var target_skeleton_path := String(target_root.get_path_to(skeleton))
	var updated_tracks := 0
	for track in range(animation.get_track_count() - 1, -1, -1):
		var original_path := animation.track_get_path(track)
		var node_path := NodePath(String(original_path.get_concatenated_names()))
		var source_node := source_root.get_node_or_null(node_path)
		var subnames := String(original_path.get_concatenated_subnames())
		if source_node is Skeleton3D and not subnames.is_empty():
			animation.track_set_path(track, NodePath(target_skeleton_path + ":" + subnames))
			updated_tracks += 1
		else:
			# Kaynaktaki karakter kok transformunu tasimak istemiyoruz.
			animation.remove_track(track)
	source_instance.queue_free()
	if updated_tracks == 0:
		push_warning("Ashvale: %s animasyonunda uyumlu iskelet kanali bulunamadi." % fbx_path)
		return ""
	animation.loop_mode = Animation.LOOP_LINEAR if should_loop else Animation.LOOP_NONE
	var library: AnimationLibrary
	if animator.has_animation_library("Ashvale"):
		library = animator.get_animation_library("Ashvale")
	else:
		library = AnimationLibrary.new()
		if animator.add_animation_library("Ashvale", library) != OK:
			return ""
	if library.has_animation(target_name):
		library.remove_animation(target_name)
	if library.add_animation(target_name, animation) != OK:
		return ""
	print("Ashvale animation imported: ", target_name, " (", updated_tracks, " tracks)")
	return "Ashvale/" + target_name


func _start_attack() -> void:
	if animator == null or attack_clip.is_empty() or attack_remaining > 0.0:
		return
	var animation := animator.get_animation(attack_clip)
	if animation == null:
		return
	attack_remaining = animation.length
	current_animation_state = "Attack"
	animator.speed_scale = 1.0
	animator.play(attack_clip, 0.12)


func _character_candidates() -> Array[String]:
	var paths: Array[String] = []
	if not character_file.strip_edges().is_empty():
		paths.append(character_file)
	for preferred in PRIORITY_CHARACTER_FILES:
		if not paths.has(preferred):
			paths.append(preferred)
	var discovered: Array[String] = []
	_collect_char1_files("res://", 0, discovered)
	discovered.sort()
	for item in discovered:
		if not paths.has(item):
			paths.append(item)
	if not paths.has(FALLBACK_MODEL_PATH):
		paths.append(FALLBACK_MODEL_PATH)
	return paths


func _collect_char1_files(directory: String, depth: int, results: Array[String]) -> void:
	if depth > 6:
		return
	var folder := DirAccess.open(directory)
	if folder == null:
		return
	for file in folder.get_files():
		var extension := file.get_extension().to_lower()
		if not extension in ["glb", "gltf", "fbx", "tscn"]:
			continue
		var file_path := directory.path_join(file)
		if "char1" in file_path.to_lower() and not results.has(file_path):
			results.append(file_path)
	for subfolder in folder.get_directories():
		if subfolder.begins_with(".") or subfolder == "addons":
			continue
		_collect_char1_files(directory.path_join(subfolder), depth + 1, results)


func _find_animator(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animator(child)
		if found != null:
			return found
	return null


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null


func _find_bone_by_suffix(names: Array[String]) -> int:
	if skeleton == null:
		return -1
	for index in range(skeleton.get_bone_count()):
		var raw := skeleton.get_bone_name(index).to_lower()
		var normalized := raw.replace(":", "").replace("_", "").replace(".", "").replace("-", "").replace(" ", "")
		for candidate in names:
			if normalized.ends_with(candidate):
				return index
	return -1


func _cache_bone_map() -> void:
	bone_map.clear()
	neutral_bone_pose.clear()
	bone_map["left_leg"] = _find_bone_by_suffix(["leftupleg", "leftupperleg", "leftthigh", "thighl", "upperlegl", "lthigh"])
	bone_map["right_leg"] = _find_bone_by_suffix(["rightupleg", "rightupperleg", "rightthigh", "thighr", "upperlegr", "rthigh"])
	bone_map["left_knee"] = _find_bone_by_suffix(["leftleg", "leftlowerleg", "leftshin", "calfl", "lowerlegl", "lcalf"])
	bone_map["right_knee"] = _find_bone_by_suffix(["rightleg", "rightlowerleg", "rightshin", "calfr", "lowerlegr", "rcalf"])
	bone_map["left_arm"] = _find_bone_by_suffix(["leftarm", "leftupperarm", "upperarml", "lupperarm"])
	bone_map["right_arm"] = _find_bone_by_suffix(["rightarm", "rightupperarm", "upperarmr", "rupperarm"])
	bone_map["spine"] = _find_bone_by_suffix(["spine", "spine1", "spine2", "spine01", "chest"])
	for value in bone_map.values():
		var index: int = int(value)
		if index >= 0:
			neutral_bone_pose[index] = skeleton.get_bone_pose_rotation(index)


func _apply_procedural_bone(bone_key: String, angle: float) -> void:
	if skeleton == null:
		return
	var index: int = int(bone_map.get(bone_key, -1))
	if index < 0:
		return
	var neutral: Quaternion = neutral_bone_pose.get(index, Quaternion.IDENTITY)
	skeleton.set_bone_pose_rotation(index, neutral * Quaternion(Vector3.RIGHT, angle))


func _animate_procedural(delta: float, moving: bool, sprinting: bool, airborne: bool) -> void:
	if skeleton == null or skeleton.get_bone_count() == 0:
		return
	motion_time += delta * (10.5 if sprinting else 7.0) if moving else delta * 1.2
	var stride := sin(motion_time) * (0.48 if sprinting else 0.29) if moving else 0.0
	var knee_left := maxf(0.0, -sin(motion_time)) * 0.25 if moving else 0.0
	var knee_right := maxf(0.0, sin(motion_time)) * 0.25 if moving else 0.0
	if airborne:
		stride *= 0.4
		knee_left = 0.15
		knee_right = 0.15
	_apply_procedural_bone("left_leg", stride)
	_apply_procedural_bone("right_leg", -stride)
	_apply_procedural_bone("left_knee", knee_left)
	_apply_procedural_bone("right_knee", knee_right)
	_apply_procedural_bone("left_arm", -stride * 0.65)
	_apply_procedural_bone("right_arm", stride * 0.65)
	_apply_procedural_bone("spine", sin(motion_time * 0.4) * 0.013)


func _update_character_animation(delta: float, moving: bool, sprinting: bool) -> void:
	var airborne := not player.is_on_floor()
	var target := ""
	if airborne:
		if player.velocity.y > 0.0 and not jump_clip.is_empty():
			target = jump_clip
		elif player.velocity.y < 0.0 and not fall_clip.is_empty():
			target = fall_clip
	if target.is_empty():
		if moving:
			if sprinting and not run_clip.is_empty():
				target = run_clip
			elif not walk_clip.is_empty():
				target = walk_clip
			elif not run_clip.is_empty():
				target = run_clip
		else:
			target = idle_clip

	if attack_remaining > 0.0:
		attack_remaining = maxf(attack_remaining - delta, 0.0)
		if attack_remaining > 0.0:
			return
	if target == idle_clip and not idle_clip.is_empty():
		current_animation_state = "Idle"
	elif target == walk_clip and not walk_clip.is_empty():
		current_animation_state = "Walking"
	elif target == run_clip and not run_clip.is_empty():
		current_animation_state = "Running" if sprinting else "Walking (Run yedek)"
	elif target == jump_clip and not jump_clip.is_empty():
		current_animation_state = "Jump"
	elif target == fall_clip and not fall_clip.is_empty():
		current_animation_state = "Fall"
	else:
		current_animation_state = "Prosedurel" if skeleton != null else "Animasyon yok"
	if animator != null:
		if not target.is_empty():
			if animator.current_animation != target or not animator.is_playing():
				animator.play(target, 0.15)
			animator.speed_scale = (1.0 if sprinting else 0.65) if target == run_clip else 1.0
		elif animator.is_playing():
			animator.stop()
	if target.is_empty():
		_animate_procedural(delta, moving, sprinting, airborne)
	if skeleton == null and moving:
		motion_time += delta * (10.5 if sprinting else 7.0)
		visuals.position.y = sin(motion_time) * 0.025
	else:
		visuals.position.y = lerpf(visuals.position.y, 0.0, minf(delta * 12.0, 1.0))


func _measure_model_bounds(model: Node3D) -> AABB:
	var bounds := AABB()
	var found := false
	var pending: Array[Node] = [model]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is MeshInstance3D:
			var mesh_node := node as MeshInstance3D
			var relative := model.global_transform.affine_inverse() * mesh_node.global_transform
			var part := relative * mesh_node.get_aabb()
			if not found:
				bounds = part
				found = true
			else:
				bounds = bounds.merge(part)
		for child in node.get_children():
			pending.append(child)
	return bounds


func _make_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	add_child(camera_pivot)
	camera_pivot.position = player.position + Vector3(0, 1.5, 0)
	camera_pivot.rotation = Vector3(pitch, yaw, 0)
	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0, 1.0, 5.0)
	camera.current = true
	camera_pivot.add_child(camera)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		var window_mode := DisplayServer.window_get_mode()
		var is_fullscreen := window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or window_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		if is_fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(1280, 720))
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_collect_resource()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.003
		pitch = clampf(pitch - event.relative.y * 0.003, -0.8, 0.35)
		camera_pivot.rotation = Vector3(pitch, yaw, 0)
	elif event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		camera_distance = clampf(camera_distance + (-0.5 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.5), 2.5, 8.5)
		camera_pivot.get_node("Camera").position.z = camera_distance
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_start_attack()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var input := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	).normalized()
	var direction := Basis(Vector3.UP, yaw) * Vector3(input.x, 0, input.y)
	var sprint := Input.is_physical_key_pressed(KEY_SHIFT) and stamina > 1.0 and input.length_squared() > 0.01
	stamina = clampf(stamina + (-22.0 if sprint else 16.0) * delta, 0.0, 100.0)
	var speed := RUN_SPEED if sprint else WALK_SPEED
	player.velocity.x = direction.x * speed
	player.velocity.z = direction.z * speed
	if not player.is_on_floor():
		player.velocity.y -= GRAVITY * delta
	elif Input.is_physical_key_pressed(KEY_SPACE):
		player.velocity.y = 6.0
	else:
		player.velocity.y = -0.1
	player.move_and_slide()
	if direction.length_squared() > 0.01:
		visuals.rotation.y = lerp_angle(visuals.rotation.y, atan2(direction.x, direction.z) + deg_to_rad(character_facing_offset), delta * 10.0)
	_update_character_animation(delta, input.length_squared() > 0.01, sprint)
	camera_pivot.global_position = camera_pivot.global_position.lerp(player.global_position + Vector3(0, 1.5, 0), minf(delta * 8.0, 1.0))
	_update_hud()
