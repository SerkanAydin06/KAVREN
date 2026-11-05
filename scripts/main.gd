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
# Tek bir dosyadan tum araziyi kaplayan seam-free malzeme.
const GROUND_ALBEDO := preload("res://assets/ground/ashvale_soil_grass_1024.webp")
const GROUND_SHADER := preload("res://assets/ground/ashvale_ground.gdshader")
const GROUND_SIZE := 160.0
const GROUND_TILE_METERS := 4.0
const STYLIZED_PREVIEW_SCENE := preload("res://scripts/stylized_asset_preview.gd")
const CHOPPABLE_TREE_SCRIPT := preload("res://scripts/choppable_tree.gd")
const AXE_SCRIPT := preload("res://scripts/stylized_axe.gd")
const CHOP_RANGE := 3.4
const CHOP_IMPACT_DELAY := 0.23
const ATTACK_PLAYBACK_SPEED := 3.0 # 2.27 sn'lik FBX hareketi ~0.76 sn'de oynat.
# Tekrarlanan FBX sahneleri paylasilan Mesh/Texture kaynaklarini kullanir.
const TREE_MODEL_PATHS := [
	"res://assets/obje/Meshy_AI_Ancient_Oak_Canopy_20261104_texture_fbx/Meshy_AI_Ancient_Oak_Canopy_20261104_texture.fbx",
	"res://assets/obje/Meshy_AI_Emerald_Sentinel_20261104_texture_fbx/Meshy_AI_Emerald_Sentinel_20261104_texture.fbx",
	"res://assets/obje/Meshy_AI_Silverleaf_Birch_1104184945_texture_fbx/Meshy_AI_Silverleaf_Birch_1104184945_texture.fbx",
	"res://assets/obje/Meshy_AI_Twisted_Elder_20261104_texture_fbx/Meshy_AI_Twisted_Elder_20261104_texture.fbx",
]
const TREE_TEXTURE_PATHS := [
	"res://assets/obje/Meshy_AI_Ancient_Oak_Canopy_20261104_texture_fbx/Meshy_AI_Ancient_Oak_Canopy_20261104_texture.png",
	"res://assets/obje/Meshy_AI_Emerald_Sentinel_20261104_texture_fbx/Meshy_AI_Emerald_Sentinel_20261104_texture.png",
	"res://assets/obje/Meshy_AI_Silverleaf_Birch_1104184945_texture_fbx/Meshy_AI_Silverleaf_Birch_1104184945_texture.png",
	"res://assets/obje/Meshy_AI_Twisted_Elder_20261104_texture_fbx/Meshy_AI_Twisted_Elder_20261104_texture.png",
]
const TREE_NAMES := ["Oak", "Pine", "Birch", "Elder"]
const TREE_HEIGHTS := [8.0, 10.0, 8.7, 7.0]
const TREE_TRUNK_RADII := [0.62, 0.40, 0.37, 0.55]
const TREE_COUNT := 24

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
var pending_chop_target: Node3D = null
var pending_chop_timer := 0.0

func _ready() -> void:
	_make_world()
	_make_player()
	_make_axe()
	_make_camera()
	_make_camp()
	_make_stylized_preview()
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
	# Dusuk poligonlu tek bir yuzey; tekrar eden 1024px PBR dokusu.
	var surface := MeshInstance3D.new()
	surface.name = "TerrainSurface"
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(GROUND_SIZE, GROUND_SIZE)
	surface.mesh = ground_mesh
	var terrain_material := ShaderMaterial.new()
	terrain_material.shader = GROUND_SHADER
	terrain_material.set_shader_parameter("ground_albedo", GROUND_ALBEDO)
	terrain_material.set_shader_parameter("meters_per_tile", GROUND_TILE_METERS)
	surface.material_override = terrain_material
	ground.add_child(surface)
	# Gorunmeyen fizik kutusu: ust seviyesi tam y=0.
	var collider := CollisionShape3D.new()
	collider.name = "TerrainCollider"
	var shape := BoxShape3D.new()
	shape.size = Vector3(GROUND_SIZE, 0.4, GROUND_SIZE)
	collider.shape = shape
	collider.position.y = -0.2
	ground.add_child(collider)
	print("Ashvale ground: ", GROUND_SIZE, "m | ", GROUND_ALBEDO.get_width(), "px | tile ", GROUND_TILE_METERS, "m")

func _make_stylized_preview() -> void:
	# Karsilastirma agaci da yeni kesme mekanigini kullanir.
	var preview := STYLIZED_PREVIEW_SCENE.new()
	preview.name = "ArtDirectionShowcase"
	add_child(preview)
	var preview_oak := preview.get_node_or_null("StylizedOak") as Node3D
	if preview_oak != null:
		preview_oak.connect("wood_dropped", Callable(self, "_register_wood_drops"))
		resource_nodes.append(preview_oak)
	print("Ashvale style preview: stylized tree + rock added")


func _add_primitive(parent: Node3D, shape_mesh: Mesh, pos: Vector3, tint: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = shape_mesh
	item.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	item.material_override = material
	parent.add_child(item)
	return item

func _ensure_tree_texture(model_root: Node3D, texture_path: String) -> void:
	# FBX malzemesi dokusuz gelirse ayni klasordeki Meshy atlasini bagla.
	var resource: Resource = load(texture_path) if ResourceLoader.exists(texture_path) else null
	if not resource is Texture2D:
		return
	var texture := resource as Texture2D
	var fallback_material := StandardMaterial3D.new()
	fallback_material.albedo_texture = texture
	fallback_material.roughness = 0.88
	fallback_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var nodes: Array[Node] = [model_root]
	while not nodes.is_empty():
		var current: Node = nodes.pop_back()
		if current is MeshInstance3D:
			var mesh_node := current as MeshInstance3D
			if mesh_node.mesh != null:
				for surface_index in range(mesh_node.mesh.get_surface_count()):
					var active_material := mesh_node.get_active_material(surface_index)
					var missing_texture := active_material == null
					if active_material is BaseMaterial3D:
						missing_texture = (active_material as BaseMaterial3D).albedo_texture == null
					if missing_texture:
						mesh_node.set_surface_override_material(surface_index, fallback_material)
		for child in current.get_children():
			nodes.append(child)


func _make_placeholder_tree(tree_root: Node3D, height_meters: float) -> void:
	# Model basarisiz olursa oyuncu tamamen agacsiz kalmasin.
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.26
	trunk.bottom_radius = 0.36
	trunk.height = height_meters * 0.5
	_add_primitive(tree_root, trunk, Vector3(0, trunk.height * 0.5, 0), Color(0.35, 0.21, 0.12))
	var crown := SphereMesh.new()
	crown.radius = height_meters * 0.19
	crown.height = height_meters * 0.52
	_add_primitive(tree_root, crown, Vector3(0, height_meters * 0.71, 0), Color(0.16, 0.30, 0.15))


func _make_camp() -> void:
	# Meshy'nin dort farkli agaci ayni mesh/texture kaynaklarini paylasir.
	# Prototipte 24 agac: karakterin etrafinda dogal, tekrar etmeyen yerlestirme.
	var forest_scenes: Array[PackedScene] = []
	for model_path in TREE_MODEL_PATHS:
		var packed: PackedScene = null
		if ResourceLoader.exists(model_path):
			var model_resource: Resource = load(model_path)
			if model_resource is PackedScene:
				packed = model_resource as PackedScene
		if packed == null:
			push_warning("Ashvale: Agac modeli yuklenemedi: " + String(model_path))
		forest_scenes.append(packed)
	var tree_random := RandomNumberGenerator.new()
	tree_random.seed = 20261104
	for i in range(TREE_COUNT):
		var kind := i % TREE_MODEL_PATHS.size()
		var direction_angle := TAU * (float(i) + tree_random.randf_range(-0.3, 0.3)) / float(TREE_COUNT)
		var distance := tree_random.randf_range(13.0, 48.0)
		var tree_pos := Vector3(cos(direction_angle) * distance, 0.0, sin(direction_angle) * distance)
		var tree := CHOPPABLE_TREE_SCRIPT.new()
		tree.name = "%s_%02d" % [TREE_NAMES[kind], i]
		tree.connect("wood_dropped", Callable(self, "_register_wood_drops"))
		tree.position = tree_pos
		tree.rotation.y = tree_random.randf_range(0.0, TAU)
		add_child(tree)
		var size_factor := tree_random.randf_range(0.84, 1.18)
		var tree_height: float = float(TREE_HEIGHTS[kind]) * size_factor
		if forest_scenes[kind] != null:
			var tree_model := forest_scenes[kind].instantiate()
			if tree_model is Node3D:
				var model_node := tree_model as Node3D
				model_node.name = "Model"
				tree.add_child(model_node)
				var bounds := _measure_model_bounds(model_node)
				if bounds.size.y > 0.01:
					var uniform_scale := tree_height / bounds.size.y
					model_node.scale = Vector3.ONE * uniform_scale
					var offset_x := bounds.position.x + bounds.size.x * 0.5
					var offset_z := bounds.position.z + bounds.size.z * 0.5
					model_node.position = Vector3(-offset_x, -bounds.position.y, -offset_z) * uniform_scale
				_ensure_tree_texture(model_node, String(TREE_TEXTURE_PATHS[kind]))
			else:
				tree_model.queue_free()
				_make_placeholder_tree(tree, tree_height)
		else:
			_make_placeholder_tree(tree, tree_height)
		var trunk_body := StaticBody3D.new()
		trunk_body.name = "TrunkBody"
		tree.add_child(trunk_body)
		var trunk_collision := CollisionShape3D.new()
		trunk_collision.name = "CollisionShape3D"
		var trunk_shape := CylinderShape3D.new()
		trunk_shape.radius = float(TREE_TRUNK_RADII[kind]) * size_factor
		trunk_shape.height = minf(tree_height * 0.46, 3.8)
		trunk_collision.shape = trunk_shape
		trunk_collision.position.y = trunk_shape.height * 0.5
		trunk_body.add_child(trunk_collision)
		tree.set_meta("resource_type", "wood")
		tree.set_meta("tree_species", String(TREE_NAMES[kind]))
		resource_nodes.append(tree)
	print("Ashvale forest: ", TREE_COUNT, " trees / ", TREE_MODEL_PATHS.size(), " species")

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
	controls.text = "WASD  Hareket    SHIFT  Koş    SPACE  Zıpla    E  Odun / Taş Topla\nFARE  Kamera / Zoom    SOL TIK  Balta / Saldırı    ESC  İmleç    F11  Tam Ekran"
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(controls)
	_update_hud()

func _update_hud() -> void:
	var nearby := _nearest_resource()
	var hint := ""
	if nearby != null:
		hint = "\n[E] %s topla" % ("ODUN" if String(nearby.get_meta("resource_type")) == "wood_drop" else "TAŞ")
	else:
		var nearby_tree := _nearest_choppable_tree()
		if nearby_tree != null:
			hint = "\n[SOL TIK] AGACI KES (%d/%d)" % [nearby_tree.hits_taken, nearby_tree.MAX_HITS]
	hud.text = "ASHVALE  •  KEŞİF\nODUN  %d     TAŞ  %d\nDAYANIKLILIK  %d%%%s\nKARAKTER  %s  |  %s\nANİMASYON  %s" % [wood, stone, int(stamina), hint, loaded_character_path.get_file().get_basename() if not loaded_character_path.is_empty() else "yok", character_animation_status, current_animation_state]

func _nearest_resource() -> Node3D:
	var best: Node3D = null
	var best_distance := 3.0
	for node in resource_nodes:
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var resource_kind := String(node.get_meta("resource_type", ""))
		if resource_kind != "wood_drop" and resource_kind != "stone":
			continue
		var distance := player.global_position.distance_to(node.global_position)
		if distance < best_distance:
			best_distance = distance
			best = node
	return best

func _nearest_choppable_tree() -> Node3D:
	var best: Node3D = null
	var best_distance := CHOP_RANGE
	var forward := Basis(Vector3.UP, yaw) * Vector3.FORWARD
	for node in resource_nodes:
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		if String(node.get_meta("resource_type", "")) != "wood" or not node.has_method("take_axe_hit"):
			continue
		var relative := node.global_position - player.global_position
		relative.y = 0.0
		var distance := relative.length()
		if distance >= best_distance or distance < 0.001:
			continue
		if forward.dot(relative / distance) < 0.22:
			continue
		best = node
		best_distance = distance
	return best

func _register_wood_drops(drops: Array) -> void:
	for item in drops:
		if item is Node3D:
			resource_nodes.append(item as Node3D)

func _collect_resource() -> void:
	var target := _nearest_resource()
	if target == null:
		return
	if String(target.get_meta("resource_type")) == "wood_drop":
		wood += int(target.get_meta("wood_amount", 1))
	else:
		stone += 1
	resource_nodes.erase(target)
	target.queue_free()
	_update_hud()

func _advance_axe_impact(delta: float) -> void:
	if pending_chop_target == null:
		return
	pending_chop_timer -= delta
	if pending_chop_timer > 0.0:
		return
	var target := pending_chop_target
	pending_chop_target = null
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		return
	if player.global_position.distance_to(target.global_position) > CHOP_RANGE + 0.4:
		return
	if target.take_axe_hit(player.global_position) and target.is_falling:
		resource_nodes.erase(target)


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
				print("Ashvale: Walking.fbx sadece sabit poz; yuruyus icin gecici olarak yavaslatilmis Run animasyonu kullaniliyor.")
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
			var hip_key_position: Vector3 = animation.track_get_key_value(track_index, key_index)
			hip_key_position.x = initial_position.x
			hip_key_position.z = initial_position.z
			animation.track_set_key_value(track_index, key_index, hip_key_position)


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
	attack_remaining = animation.length / ATTACK_PLAYBACK_SPEED
	current_animation_state = "Attack"
	animator.speed_scale = ATTACK_PLAYBACK_SPEED
	animator.play(attack_clip, 0.05)
	pending_chop_target = _nearest_choppable_tree()
	pending_chop_timer = CHOP_IMPACT_DELAY if pending_chop_target != null else 0.0


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


func _make_axe() -> void:
	# Mixamo el kemigine bagla; iskelet yoksa gorunur yedek elde tasi.
	var mount: Node3D = visuals
	if skeleton != null:
		var hand_bone := ""
		for bone_index in range(skeleton.get_bone_count()):
			var possible_name := String(skeleton.get_bone_name(bone_index))
			var compact_name := possible_name.to_lower().replace("_", "").replace(":", "")
			if compact_name.ends_with("righthand"):
				hand_bone = possible_name
				break
		if not hand_bone.is_empty():
			var attachment := BoneAttachment3D.new()
			attachment.name = "AxeRightHand"
			attachment.bone_name = hand_bone
			skeleton.add_child(attachment)
			mount = attachment
	var axe := AXE_SCRIPT.new()
	axe.name = "StarterAxe"
	mount.add_child(axe)
	if mount == visuals:
		axe.position = Vector3(0.42, 1.17, -0.2)
		axe.rotation_degrees = Vector3(0, -12, -24)
	else:
		axe.position = Vector3(0, -0.13, 0.06)
		axe.rotation_degrees = Vector3(87, 0, -12)


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
	_advance_axe_impact(delta)
	camera_pivot.global_position = camera_pivot.global_position.lerp(player.global_position + Vector3(0, 1.5, 0), minf(delta * 8.0, 1.0))
	_update_hud()
