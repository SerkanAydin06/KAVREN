extends Node3D

const FALLBACK_MODEL_PATH := "res://assets/characters/base_adventurer_running.glb"
const CHAR1_IDLE_PATH := "res://assets/characters/Char1/Idle.fbx"
const CHAR1_WALK_ANIMATION_PATH := "res://assets/characters/Char1/Walking_Animated.fbx"
const CHAR1_RUNNING_PATH := "res://assets/characters/Char1/Running.fbx"
const CHAR1_ATTACK_PATH := "res://assets/characters/Char1/Standing Melee Attack Downward.fbx"
const CHAR1_JUMP_PATH := "res://assets/characters/Char1/Jump.fbx"
const CHAR1_DEATH_PATH := "res://assets/characters/Char1/Dying Backwards.fbx"
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
# Hizlar Mixamo kliplerinin adim uzunluguna yakin secildi; animasyon hizi
# ayrica hareket hizina gore olceklenir, ayaklar yerde kaymaz.
const WALK_SPEED := 2.5
const RUN_SPEED := 6.5
const SPRINT_RECOVERY_STAMINA := 25.0
const FALL_POSE_DELAY := 0.09
const MODEL_HEIGHT := 1.8
const GRAVITY := 18.0
# Tek bir dosyadan tum araziyi kaplayan seam-free malzeme.
const GROUND_ALBEDO := preload("res://assets/ground/ashvale_soil_grass_1024.webp")
const GROUND_SHADER := preload("res://assets/ground/ashvale_ground.gdshader")
const GROUND_SIZE := 600.0 # ufukta zemin kenari gorunmesin
const GROUND_TILE_METERS := 4.0
const STYLIZED_PREVIEW_SCENE := preload("res://scripts/stylized_asset_preview.gd")
const AXE_CHOP_ANIMATION := preload("res://scripts/axe_chop_animation.gd")
const CHOPPABLE_TREE_SCRIPT := preload("res://scripts/choppable_tree.gd")
const AXE_SCRIPT := preload("res://scripts/stylized_axe.gd")
const MODEL_LIBRARY := preload("res://scripts/model_library.gd")
const ATMOSPHERE_SCRIPT := preload("res://scripts/atmosphere.gd")
const CAMPFIRE_SCRIPT := preload("res://scripts/campfire.gd")
const MINEABLE_ROCK_SCRIPT := preload("res://scripts/mineable_rock.gd")
const ITEMS := preload("res://scripts/items.gd")
const INVENTORY_SCRIPT := preload("res://scripts/inventory.gd")
const GAME_UI_SCRIPT := preload("res://scripts/ui/game_ui.gd")
const TORCH_SCRIPT := preload("res://scripts/torch.gd")
const STARTING_ITEMS := [["stone_axe", 1], ["stone_pickaxe", 1]]
const FERN_FIBER := 2
const FERN_REGROW_SECONDS := 240.0
const FERN_REACH := 1.8
const PLACE_DISTANCE := 2.2
const PLACE_CLEARANCE := 1.4
# Vurus erisimi: oyuncu merkezinden agac govdesi / kaya YUZEYINE metre.
const MELEE_REACH := 1.0
const MELEE_FACING_DOT := 0.5 # ~60 derecelik on koni
# Jump.fbx (2.17 sn) zaman cizelgesi: 0.20-0.55 comelme, ~0.75 kalkis,
# 1.05 tepe, ~1.30 inis, 1.45 inis comelmesi, 1.75 toparlanma.
const JUMP_VELOCITY := 6.0
const JUMP_CLIP_START := 0.62 # comelmenin sonundan basla: tus gecikmesi kisa kalsin
const JUMP_CLIP_TAKEOFF := 0.75
const JUMP_CLIP_LANDING := 1.30
const JUMP_CLIP_RECOVERED := 1.75
# Klipteki havada kalma suresini fizikteki ucus suresine (2v/g) esitle.
const JUMP_PLAYBACK_SPEED := (JUMP_CLIP_LANDING - JUMP_CLIP_TAKEOFF) / (2.0 * JUMP_VELOCITY / GRAVITY)
const JUMP_TAKEOFF_DELAY := (JUMP_CLIP_TAKEOFF - JUMP_CLIP_START) / JUMP_PLAYBACK_SPEED
# Can ve kamp atesi.
const MAX_HEALTH := 100.0
const FIRE_DAMAGE_PER_SECOND := 34.0
const FIRE_RADIUS := 0.95
const HEALTH_REGEN_PER_SECOND := 3.0
const HEALTH_REGEN_DELAY := 4.0
const CAMP_POSITION := Vector3(3, 0, 2)
const SPAWN_POSITION := Vector3(0, 0.1, 0)
const HAND_GRIP_SCRIPT := preload("res://scripts/hand_grip.gd")
# Meshy aletlerinin sap konumu (model boyuna oranla). handle_x: sapin
# sinir kutusu merkezine gore X kaymasi; grip_height: tutus yuksekligi;
# blade_sign: agzin +X (1) mi -X (-1) mi tarafinda oldugu.
const TOOL_GRIPS := {
	"hand_axe": {"handle_x": 0.105, "grip_height": 0.16, "blade_sign": -1.0},
	"pickaxe": {"handle_x": 0.02, "grip_height": 0.16, "blade_sign": 1.0},
}
const GRIP_ALONG_PALM := 0.78 # el kokunden parmak koklerine oran
const GRIP_PALM_OFFSET := 0.032 # metre, avuc yuzeyinden sap merkezine
const CHOP_IMPACT_DELAY := 0.25
const ATTACK_PLAYBACK_SPEED := 3.0 # 2.28 sn'lik AxeChop klibini ~0.76 sn'de oynat.
# Tekrarlanan FBX sahneleri paylasilan Mesh/Texture kaynaklarini kullanir.
const TREE_MODEL_KEYS := ["ancient_oak", "emerald_pine", "silverleaf_birch", "twisted_elder"]
const TREE_MODEL_PATHS := [
	"res://assets/environment/trees/ancient_oak/ancient_oak.fbx",
	"res://assets/environment/trees/emerald_pine/emerald_pine.fbx",
	"res://assets/environment/trees/silverleaf_birch/silverleaf_birch.fbx",
	"res://assets/environment/trees/twisted_elder/twisted_elder.fbx",
]
const TREE_TEXTURE_PATHS := [
	"res://assets/environment/trees/ancient_oak/ancient_oak_albedo.png",
	"res://assets/environment/trees/emerald_pine/emerald_pine_albedo.png",
	"res://assets/environment/trees/silverleaf_birch/silverleaf_birch_albedo.png",
	"res://assets/environment/trees/twisted_elder/twisted_elder_albedo.png",
]
const TREE_NAMES := ["Oak", "Pine", "Birch", "Elder"]
const TREE_HEIGHTS := [8.0, 10.0, 8.7, 7.0]
# Bel hizasindaki (~1 m) gorunen govde yaricapi, metre (Meshy mesh olcumu).
const TREE_TRUNK_RADII := [0.78, 0.5, 0.36, 0.85]
# Kok uclari topraga girsin diye model, boyunun bu orani kadar gomulur.
const TREE_ROOT_SINK := [0.045, 0.04, 0.045, 0.055]
const TREE_COUNT := 24
# Kazma ile kirilan kaynaklar: model, kaynak turu, yukseklik, vurus, parca sayisi.
const ROCK_TYPES := {
	"stone_boulder": {"kind": "stone", "height": 1.15, "hits": 3, "drops": 2},
	"mossy_boulder": {"kind": "stone", "height": 1.35, "hits": 3, "drops": 3},
	"copper_ore": {"kind": "copper", "height": 1.0, "hits": 4, "drops": 2},
	"iron_ore": {"kind": "iron", "height": 1.2, "hits": 5, "drops": 2},
}
const FERN_COUNT := 36
const DECOR_STUMP_COUNT := 5

var player: CharacterBody3D
var visuals: Node3D
var camera_pivot: Node3D
var animator: AnimationPlayer
var skeleton: Skeleton3D
var run_clip := ""
var walk_clip := ""
var walk_clip_speed := 0.0 # klibin kendi ilerleme hizi, m/s
var run_clip_speed := 0.0
var idle_clip := ""
var jump_clip := ""
var fall_clip := ""
var attack_clip := ""
var death_clip := ""
var jump_phase := "" # "", "crouch", "air", "land"
var jump_timer := 0.0
var health := MAX_HEALTH
var is_dead := false
var time_since_damage := 99.0
var burning := false
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
# Kaynak sayaclari envanterden okunur (eski kod ve testler icin kisayol).
var inventory: RefCounted = INVENTORY_SCRIPT.new()
var wood: int:
	get: return inventory.count("wood")
	set(value): inventory.set_count("wood", value)
var stone: int:
	get: return inventory.count("stone")
	set(value): inventory.set_count("stone", value)
var copper: int:
	get: return inventory.count("copper")
	set(value): inventory.set_count("copper", value)
var iron: int:
	get: return inventory.count("iron")
	set(value): inventory.set_count("iron", value)
var active_tool := "" # "axe", "pickaxe", "torch", "place" ya da "" (bos el)
var selected_slot := 0
var equipped_item := ""
var ui: CanvasLayer
var torch: Node3D
var placement_ghost: Node3D
var placement_valid := false
const MINE := preload("res://scripts/abandoned_mine.gd")
enum Expedition { FIND, RETURN, MINE_IRON, COMPLETE }
var expedition_stage := Expedition.FIND
var mine_iron_collected := false
var campfires: Array[Node3D] = []
var warmth := 100.0
var night_started := false
var survived_first_night := false
var night_failed := false
var fire_positions: Array[Vector3] = [CAMP_POSITION]
var _tool_materials: Dictionary = {}
var equipped_pickaxe: Node3D
var stamina := 100.0
var sprint_exhausted := false
var ungrounded_time := 0.0
var camera_distance := 5.0
var pending_chop_target: Node3D = null
var pending_chop_timer := 0.0
var equipped_axe: Node3D
var axe_attachment: Node3D
var hand_grip: Node
var atmosphere: Node3D
const SAVE := preload("res://scripts/session_save.gd")
const WORLD_LIMIT := GROUND_SIZE * 0.5 - 1.5
var harvested := {}
var save_elapsed := 0.0
var hud_elapsed := 0.0
var session_active := false
var writable_session := true
var checkpoint_pending := false

func _ready() -> void:
	for entry in STARTING_ITEMS:
		inventory.add(String(entry[0]), int(entry[1]))
	_make_world()
	_make_player()
	_make_axe()
	_make_camera()
	_make_camp()
	_make_stylized_preview()
	_make_hud()
	_select_slot(0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	call_deferred("_open_session")

func _open_session() -> void:
	# Diagnostics instantiate this scene independently of the player's session.
	if get_tree().current_scene != self:
		return
	session_active = true
	if FileAccess.file_exists(SAVE.PATH):
		var data := SAVE.read_state()
		writable_session = not data.is_empty()
		if writable_session:
			SAVE.restore(self, data)
		else:
			ui.toast("Kayıt okunamadı. Mevcut dosya korunuyor.")

func _schedule_checkpoint() -> void:
	if session_active and writable_session and not checkpoint_pending:
		checkpoint_pending = true
		call_deferred("_checkpoint")

func _checkpoint() -> void:
	checkpoint_pending = false
	if session_active and writable_session and not SAVE.write_state(SAVE.capture(self)):
		ui.toast("Oyun kaydedilemedi.")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_checkpoint()

func _make_world() -> void:
	# Gokyuzu, gun-gece dongusu, gunes/ay, GI, sis: scripts/atmosphere.gd
	atmosphere = ATMOSPHERE_SCRIPT.new()
	atmosphere.name = "Atmosphere"
	add_child(atmosphere)
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
	terrain_material.set_shader_parameter("camp_center", Vector2(CAMP_POSITION.x, CAMP_POSITION.z))
	terrain_material.set_shader_parameter("mine_entry", Vector2(MINE.ENTRANCE.x, MINE.ENTRANCE.z))
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
		preview_oak.connect("wood_dropped", _register_drops.bind(preview_oak))
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
	add_child(preload("res://scripts/valley_scenery.gd").new())
	# Meshy'nin dort farkli agaci ayni mesh/texture kaynaklarini paylasir.
	# Prototipte 24 agac: karakterin etrafinda dogal, tekrar etmeyen yerlestirme.
	var forest_scenes: Array[PackedScene] = []
	for model_path in TREE_MODEL_PATHS:
		var packed: PackedScene = null
		if ResourceLoader.exists(model_path):
			var model_resource: Resource = load(String(model_path))
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
		# Keep canopy silhouettes to either side of the view toward the hoist.
		if tree_pos.z < -6 and absf(tree_pos.x) < 7:
			tree_pos.x += 9.0 if tree_pos.x >= 0 else -9.0
		var tree := CHOPPABLE_TREE_SCRIPT.new()
		tree.name = "%s_%02d" % [TREE_NAMES[kind], i]
		tree.connect("wood_dropped", _register_drops.bind(tree))
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
					model_node.position.y -= tree_height * float(TREE_ROOT_SINK[kind])
				if MODEL_LIBRARY.apply_material(model_node, String(TREE_MODEL_KEYS[kind])) == 0:
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

	var mine := MINE.new()
	mine.name = "AbandonedMine"
	mine.position = MINE.ENTRANCE
	add_child(mine)
	_make_mineables()
	_make_ferns()
	_make_decor_stumps()
	var camp := Node3D.new()
	camp.name = "Camp"
	camp.position = CAMP_POSITION
	add_child(camp)
	var fire := CAMPFIRE_SCRIPT.new()
	fire.name = "Campfire"
	camp.add_child(fire)
	campfires.append(fire)

func _make_mineables() -> void:
	# Kampa yakin taslar, daha uzakta bakir ve demir cevheri damarlari.
	var placements: Array = []
	for i in range(10):
		var angle := float(i) * TAU / 10.0 + 0.23
		placements.append(["stone_boulder" if i % 2 == 0 else "mossy_boulder", angle, 6.0 + float(i % 3) * 3.5])
	for i in range(4):
		placements.append(["copper_ore", 0.6 + float(i) * 0.35, 18.0 + float(i % 2) * 4.0])
	for i in range(3):
		placements.append(["iron_ore", PI + 0.4 + float(i) * 0.4, 24.0 + float(i % 2) * 5.0])
	var counts: Dictionary = {}
	var rock_random := RandomNumberGenerator.new()
	rock_random.seed = 20261105
	for entry in placements:
		var key := String(entry[0])
		var index: int = counts.get(key, 0)
		counts[key] = index + 1
		var location := Vector3(cos(entry[1]), 0, sin(entry[1])) * float(entry[2])
		_spawn_rock(key, "%s_%02d" % [key.to_pascal_case(), index], location, rock_random)
	for index in range(3):
		var offset := Vector3(-5.5 + index * 5, 0, 5 + index % 2 * 2)
		_spawn_rock("copper_ore", "MineCopper%d" % index, MINE.ENTRANCE + offset, rock_random)
	_spawn_rock("iron_ore", MINE.IRON_SOURCE, MINE.ENTRANCE + Vector3(0.8, 0, -16), rock_random)
	print("Ashvale mineables: ", counts, " + 3 mine copper / 1 mine iron")

func _spawn_rock(key: String, rock_name: String, location: Vector3, rock_random: RandomNumberGenerator) -> void:
	var config: Dictionary = ROCK_TYPES[key]
	var rock := MINEABLE_ROCK_SCRIPT.new()
	rock.name = rock_name
	rock.resource_kind = String(config["kind"])
	rock.max_hits = int(config["hits"])
	rock.drop_count = int(config["drops"])
	rock.position = location
	rock.rotation.y = rock_random.randf_range(0.0, TAU)
	add_child(rock)
	var height: float = float(config["height"]) * rock_random.randf_range(0.85, 1.15)
	var model := MODEL_LIBRARY.instantiate(key, height)
	var footprint := Vector3(height, height, height)
	if model != null:
		rock.add_child(model)
		footprint = MODEL_LIBRARY.measure_bounds(model).size * model.scale.x
	else:
		var fallback := SphereMesh.new()
		fallback.radius = height * 0.55
		fallback.height = height
		_add_primitive(rock, fallback, Vector3(0, height * 0.5, 0), Color(0.40, 0.43, 0.43))
	var rock_body := StaticBody3D.new()
	rock_body.name = "RockBody"
	rock.add_child(rock_body)
	var rock_collision := CollisionShape3D.new()
	rock_collision.name = "CollisionShape3D"
	var rock_shape := CylinderShape3D.new()
	rock_shape.radius = maxf(minf(footprint.x, footprint.z) * 0.42, 0.25)
	rock_shape.height = maxf(footprint.y, 0.3)
	rock_collision.shape = rock_shape
	rock_collision.position.y = rock_shape.height * 0.5
	rock_body.add_child(rock_collision)
	rock.set_meta("resource_type", "mineable")
	rock.set_meta("rock_model", key)
	rock.connect("resources_dropped", _register_drops.bind(rock))
	resource_nodes.append(rock)

func _make_ferns() -> void:
	# Sadece dekor: carpisma yok, golge yok, uzakta gizlenir (Meshy egrelti cok poligonlu).
	var fern_random := RandomNumberGenerator.new()
	fern_random.seed = 361
	var placed := 0
	for i in range(FERN_COUNT):
		var angle := fern_random.randf_range(0.0, TAU)
		var distance := fern_random.randf_range(7.0, 50.0)
		var model := MODEL_LIBRARY.instantiate("fern", fern_random.randf_range(0.6, 1.0))
		if model == null:
			break
		var fern := Node3D.new()
		fern.name = "Fern_%02d" % i
		fern.position = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		fern.rotation.y = fern_random.randf_range(0.0, TAU)
		fern.add_child(model)
		MODEL_LIBRARY.set_visibility_range(model, 40.0, false)
		fern.set_meta("resource_type", "fern")
		add_child(fern)
		resource_nodes.append(fern)
		placed += 1
	print("Ashvale ferns: ", placed)

func _make_decor_stumps() -> void:
	# Eski kesimlerden kalmis kutukler: ormanin icine dogal detay.
	for i in range(DECOR_STUMP_COUNT):
		var angle := float(i) * TAU / float(DECOR_STUMP_COUNT) + 0.9
		var model := MODEL_LIBRARY.instantiate("tree_stump", 0.7 + float(i % 2) * 0.15)
		if model == null:
			return
		var stump := Node3D.new()
		stump.name = "OldStump_%02d" % i
		stump.position = Vector3(cos(angle) * (11.0 + float(i) * 1.7), 0, sin(angle) * (11.0 + float(i) * 1.7))
		stump.rotation.y = float(i) * 1.3
		stump.add_child(model)
		var body := StaticBody3D.new()
		body.name = "StumpBody"
		stump.add_child(body)
		var collision := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = 0.42
		shape.height = 0.6
		collision.shape = shape
		collision.position.y = 0.3
		body.add_child(collision)
		add_child(stump)

func _make_hud() -> void:
	ui = GAME_UI_SCRIPT.new()
	ui.name = "GameUI"
	add_child(ui)
	ui.setup(inventory)
	hud = ui.hint_label
	inventory.changed.connect(_on_inventory_changed)
	_update_hud()

func _on_inventory_changed() -> void:
	_schedule_checkpoint()
	# Secili yuvadaki esya degistiyse (uretim, surukleme, kurulum) yeniden kusan.
	if inventory.item_at(selected_slot) != equipped_item:
		_equip_selected()

func _update_hud() -> void:
	if ui == null:
		return
	var hint := ""
	var nearby := _nearest_resource()
	var fern := _nearest_fern()
	var power := ITEMS.tool_power(equipped_item)
	var fire := _closest_fire(3.0)
	if is_dead:
		hint = "ÖLDÜN  —  [R] kampta yeniden doğ"
	elif burning:
		hint = "ATEŞ YAKIYOR!  Uzaklaş"
	elif nearby != null:
		var kind := String(nearby.get_meta("resource_type")).trim_suffix("_drop")
		hint = "[E]  %s topla" % ITEMS.display_name(kind)
	elif fern != null:
		hint = "[E]  Bitki lifi topla"
	elif fire != null:
		hint = "[E] Odun ekle  ·  %d sn yakıt" % ceili(fire.fuel) if fire.fuel > 0 else "[E] Ateşi yak  ·  1 odun"
	elif active_tool == "axe":
		var tree := _nearest_choppable_tree()
		if tree != null:
			hint = "[SOL TIK]  Ağacı kes   (%d darbe)" % tree.remaining_hits(power)
		elif _nearest_mineable_rock() != null:
			hint = "Kayayı kırmak için kazma seç"
	elif active_tool == "pickaxe":
		var rock := _nearest_mineable_rock()
		if rock != null:
			var need: int = ITEMS.MINE_TIER.get(rock.resource_kind, 1)
			if ITEMS.tool_tier(equipped_item) < need:
				hint = "%s için Bakır Kazma veya daha iyisi gerekli" % ITEMS.display_name(rock.resource_kind)
			else:
				hint = "[SOL TIK]  %s kaz   (%d darbe)" % [ITEMS.display_name(rock.resource_kind), rock.remaining_hits(power)]
		elif _nearest_choppable_tree() != null:
			hint = "Ağacı kesmek için balta seç"
	elif active_tool == "place":
		hint = "[SOL TIK]  Kamp ateşini kur" if placement_valid else "Buraya kurulamaz"
	ui.set_hint(hint)
	ui.set_status(health, MAX_HEALTH, stamina)
	var goal := ""
	if not survived_first_night:
		if night_started:
			goal = "Gün doğana kadar sıcak kal." if not night_failed else "Bir sonraki geceye hazırlan."
		else:
			goal = "Akşam olmadan odun biriktir." if atmosphere.hour < 17 else "Hava soğuyor. Ateşe odun ekle."
	else:
		goal = _expedition_hint()
	ui.set_survival(warmth, goal)
	if atmosphere != null:
		ui.set_clock(atmosphere.clock_text(), _night_now())
	ui.set_debug("KARAKTER  %s  |  %s\nANİMASYON  %s\nPOZİSYON  %s\nFPS  %d" % [loaded_character_path.get_file().get_basename() if not loaded_character_path.is_empty() else "yok", character_animation_status, current_animation_state, str(player.global_position.snapped(Vector3.ONE * 0.1)), Engine.get_frames_per_second()])

func _nearest_fern() -> Node3D:
	var best: Node3D = null
	var best_distance := FERN_REACH
	for node in resource_nodes:
		if not is_instance_valid(node) or not node.visible or String(node.get_meta("resource_type", "")) != "fern":
			continue
		var relative := node.global_position - player.global_position
		relative.y = 0.0
		if relative.length() < best_distance:
			best_distance = relative.length()
			best = node
	return best

func _nearest_resource() -> Node3D:
	var best: Node3D = null
	var best_distance := 3.0
	for node in resource_nodes:
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		if not String(node.get_meta("resource_type", "")).ends_with("_drop"):
			continue
		var distance := player.global_position.distance_to(node.global_position)
		if distance < best_distance and _mine_path_clear(node):
			best_distance = distance
			best = node
	return best

func _mine_path_clear(node: Node3D) -> bool:
	if node.position.distance_squared_to(MINE.ENTRANCE) > 40 * 40:
		return true
	var ray := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, node.global_position + Vector3.UP * 0.5, 4)
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func _nearest_mineable_rock() -> Node3D:
	return _nearest_melee_target("mineable", "take_pickaxe_hit")

func _nearest_choppable_tree() -> Node3D:
	return _nearest_melee_target("wood", "take_axe_hit")

func _target_radius(node: Node3D) -> float:
	# Agac/kaya carpisma silindirinin yaricapi = vurulacak yuzey.
	for body_name in ["TrunkBody", "RockBody", "CollisionBody"]:
		var collision := node.get_node_or_null(body_name + "/CollisionShape3D") as CollisionShape3D
		if collision != null:
			if collision.shape is CylinderShape3D:
				return (collision.shape as CylinderShape3D).radius
			if collision.shape is SphereShape3D:
				return (collision.shape as SphereShape3D).radius
			if collision.shape is CapsuleShape3D:
				return (collision.shape as CapsuleShape3D).radius
	return 0.4

func _surface_distance(node: Node3D) -> float:
	var relative := node.global_position - player.global_position
	relative.y = 0.0
	return relative.length() - _target_radius(node)

func _nearest_melee_target(resource_type: String, hit_method: String) -> Node3D:
	var best: Node3D = null
	var best_distance := MELEE_REACH
	var forward := Basis(Vector3.UP, yaw) * Vector3.FORWARD
	for node in resource_nodes:
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		if String(node.get_meta("resource_type", "")) != resource_type or not node.has_method(hit_method):
			continue
		var relative := node.global_position - player.global_position
		relative.y = 0.0
		if relative.length() < 0.001:
			continue
		var distance := _surface_distance(node)
		if distance > best_distance:
			continue
		if forward.dot(relative.normalized()) < MELEE_FACING_DOT or not _mine_path_clear(node):
			continue
		best = node
		best_distance = distance
	return best

func _register_drops(drops: Array, source: Node3D) -> void:
	var path := String(get_path_to(source))
	harvested[path] = true
	_schedule_checkpoint()
	for item in drops:
		if item is Node3D:
			item.set_meta("harvest_source", path)
			resource_nodes.append(item as Node3D)

func _collect_resource() -> void:
	var target := _nearest_resource()
	if target == null:
		_harvest_fern()
		return
	var kind := String(target.get_meta("resource_type")).trim_suffix("_drop")
	var amount := int(target.get_meta("wood_amount", target.get_meta("amount", 1)))
	var leftover: int = inventory.add(kind, amount)
	if leftover >= amount:
		if ui != null:
			ui.toast("Envanter dolu", "", Color(0.95, 0.42, 0.36))
		return
	if kind == "iron" and target.get_meta("harvest_source", "") == MINE.IRON_SOURCE:
		mine_iron_collected = true
	if leftover > 0:
		target.set_meta("wood_amount", leftover)
		target.set_meta("amount", leftover)
		return
	resource_nodes.erase(target)
	target.queue_free()
	_update_hud()

func _harvest_fern() -> void:
	var fern := _nearest_fern()
	if fern == null:
		return
	if inventory.space_for("fiber") < FERN_FIBER:
		if ui != null:
			ui.toast("Envanter dolu", "", Color(0.95, 0.42, 0.36))
		return
	inventory.add("fiber", FERN_FIBER)
	_regrow_fern(fern, FERN_REGROW_SECONDS)

func _regrow_fern(fern: Node3D, delay: float) -> void:
	fern.visible = false
	fern.set_meta("regrow_end", Time.get_ticks_msec() + int(delay * 1000))
	# Egrelti bir sure sonra yeniden buyur.
	get_tree().create_timer(delay).timeout.connect(func() -> void:
		if is_instance_valid(fern):
			fern.scale = Vector3.ONE * 0.2
			fern.visible = true
			fern.create_tween().tween_property(fern, "scale", Vector3.ONE, 1.5).set_trans(Tween.TRANS_BACK))

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
	if target.has_method("take_axe_hit"):
		if _surface_distance(target) > MELEE_REACH + 0.3:
			return
		if target.take_axe_hit(player.global_position, ITEMS.tool_power(equipped_item)) and target.is_falling:
			resource_nodes.erase(target)
	elif target.has_method("take_pickaxe_hit"):
		if _surface_distance(target) > MELEE_REACH + 0.3:
			return
		var need: int = ITEMS.MINE_TIER.get(target.resource_kind, 1)
		if ITEMS.tool_tier(equipped_item) < need:
			if ui != null:
				ui.toast("Kazma çok zayıf: %s için Bakır Kazma gerekli" % ITEMS.display_name(target.resource_kind), "copper_pickaxe", Color(0.95, 0.42, 0.36))
			return
		if target.take_pickaxe_hit(player.global_position, ITEMS.tool_power(equipped_item)) and target.is_depleted:
			resource_nodes.erase(target)

# Eski arayuz: alet turune gore hotbar'daki ilk uygun yuvayi sec.
func _select_tool(tool_name: String) -> void:
	for i in range(inventory.HOTBAR_SIZE):
		if ITEMS.tool_kind(inventory.item_at(i)) == tool_name:
			_select_slot(i)
			return

func _select_slot(index: int) -> void:
	if attack_remaining > 0.0 or index < 0 or index >= inventory.HOTBAR_SIZE:
		return
	selected_slot = index
	_equip_selected()
	if ui != null:
		ui.set_selected(index)

func _equip_selected() -> void:
	equipped_item = inventory.item_at(selected_slot)
	active_tool = ITEMS.tool_kind(equipped_item)
	if equipped_axe != null:
		equipped_axe.visible = active_tool == "axe"
		if active_tool == "axe":
			_tint_tool(equipped_axe, equipped_item)
	if equipped_pickaxe != null:
		equipped_pickaxe.visible = active_tool == "pickaxe"
		if active_tool == "pickaxe":
			_tint_tool(equipped_pickaxe, equipped_item)
	if torch != null:
		torch.visible = active_tool == "torch"
		torch.light.visible = torch.visible
	if placement_ghost != null:
		placement_ghost.visible = active_tool == "place"
	if hud != null:
		_update_hud()

func _tint_tool(tool: Node3D, item_id: String) -> void:
	# Ayni Meshy modeli; seviye rengine gore malzeme kopyasi (tas/bakir/demir).
	var tint: Color = ITEMS.info(item_id).get("tint", Color.WHITE)
	var key := String(tool.get_meta("model_key", "")) + ":" + item_id
	for node in tool.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		if not _tool_materials.has(key):
			var base := MODEL_LIBRARY.material(String(tool.get_meta("model_key", "")))
			if base == null:
				return
			var tinted := base.duplicate() as StandardMaterial3D
			tinted.albedo_color = tint
			_tool_materials[key] = tinted
		for surface in range(mesh_node.get_surface_override_material_count()):
			mesh_node.set_surface_override_material(surface, _tool_materials[key])

func _make_placement_ghost() -> void:
	placement_ghost = Node3D.new()
	placement_ghost.name = "PlacementGhost"
	placement_ghost.visible = false
	add_child(placement_ghost)
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.62
	torus.outer_radius = 0.98
	ring.mesh = torus
	ring.scale = Vector3(1, 0.35, 1)
	ring.position.y = 0.06
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.4, 1.0, 0.5, 0.45)
	ring.material_override = mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	placement_ghost.add_child(ring)

func _update_placement() -> void:
	if placement_ghost == null or not placement_ghost.visible:
		return
	var forward := Basis(Vector3.UP, yaw) * Vector3.FORWARD
	var spot := player.global_position + forward * PLACE_DISTANCE
	spot.y = 0.0
	placement_ghost.global_position = spot
	placement_valid = _placement_clear(spot)
	var mat := (placement_ghost.get_node("Ring") as MeshInstance3D).material_override as StandardMaterial3D
	mat.albedo_color = Color(0.4, 1.0, 0.5, 0.45) if placement_valid else Color(1.0, 0.35, 0.3, 0.45)

func _placement_clear(spot: Vector3) -> bool:
	if absf(spot.x) > WORLD_LIMIT or absf(spot.z) > WORLD_LIMIT:
		return false
	for fire in fire_positions:
		if Vector2(fire.x - spot.x, fire.z - spot.z).length() < 2.2:
			return false
	for node in resource_nodes:
		if not is_instance_valid(node) or not node.visible:
			continue
		var kind := String(node.get_meta("resource_type", ""))
		if kind != "wood" and kind != "mineable":
			continue
		var distance := Vector2(node.global_position.x - spot.x, node.global_position.z - spot.z).length()
		if distance < _target_radius(node) + PLACE_CLEARANCE:
			return false
	return true

func _place_campfire() -> bool:
	_update_placement()
	if not placement_valid or equipped_item != "campfire":
		if ui != null:
			ui.toast("Buraya kurulamaz", "campfire", Color(0.95, 0.42, 0.36))
		return false
	var spot := placement_ghost.global_position
	if not inventory.remove_from_slot(selected_slot, 1):
		return false
	_add_placed_fire(spot)
	if ui != null:
		ui.toast("Kamp ateşi kuruldu", "campfire")
	return true

func _add_placed_fire(spot: Vector3) -> void:
	var fire := CAMPFIRE_SCRIPT.new()
	fire.name = "PlacedCampfire_%d" % fire_positions.size()
	add_child(fire)
	fire.global_position = spot
	fire_positions.append(spot)
	campfires.append(fire)


func _make_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = SPAWN_POSITION
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
	_style_character(character)
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
		var imported_jump := _import_external_clip(CHAR1_JUMP_PATH, "Jump", false)
		var imported_death := _import_external_clip(CHAR1_DEATH_PATH, "Death", false)
		if not imported_jump.is_empty():
			jump_clip = imported_jump
			_flatten_upward_root_motion(animator.get_animation(jump_clip))
		if not imported_death.is_empty():
			death_clip = imported_death
		if not imported_idle.is_empty():
			idle_clip = imported_idle
		if not imported_walk.is_empty():
			walk_clip = imported_walk
		if not imported_run.is_empty():
			run_clip = imported_run
		if not imported_attack.is_empty():
			attack_clip = imported_attack
		# Gameplay now uses a dedicated axe swing, not the unarmed FBX clip.
		var dedicated_axe_clip: String = AXE_CHOP_ANIMATION.create(skeleton, animator, idle_clip)
		if not dedicated_axe_clip.is_empty():
			attack_clip = dedicated_axe_clip
		# Mixamo kliplerinde root bone ileri dogru hareket edebilir.
		# CharacterBody3D zaten hareket ettigi icin yatay root motion cikarilir.
		walk_clip_speed = _clip_travel_speed(walk_clip)
		run_clip_speed = _clip_travel_speed(run_clip)
		print("Ashvale locomotion: walk clip ", snappedf(walk_clip_speed, 0.01), " m/s, run clip ", snappedf(run_clip_speed, 0.01), " m/s")
		for selected_clip in [idle_clip, walk_clip, run_clip, attack_clip, jump_clip]:
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
	print("Ashvale character: ", loaded_character_path, " | skeleton: ", skeleton != null, " | clips: ", idle_clip, "/", walk_clip, "/", run_clip, "/", jump_clip, "/", attack_clip, "/", death_clip)

func _style_character(character: Node3D) -> void:
	# Work on material copies so all original skin, hair transparency and rig data survive.
	var materials := {}
	for child in character.find_children("*", "MeshInstance3D", true, false):
		var body := child as MeshInstance3D
		if body.mesh == null:
			continue
		for surface in range(body.mesh.get_surface_count()):
			var original := body.get_active_material(surface) as StandardMaterial3D
			if original == null:
				continue
			if not materials.has(original):
				var painted := original.duplicate() as StandardMaterial3D
				painted.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
				painted.specular_mode = BaseMaterial3D.SPECULAR_TOON
				painted.normal_scale *= 0.3
				painted.roughness = maxf(0.78, painted.roughness)
				materials[original] = painted
			body.set_surface_override_material(surface, materials[original])

func _clip_travel_speed(clip_name: String) -> float:
	# Mixamo "In Place" olmayan kliplerde kalca ileri gider; bu mesafe/sure
	# animasyonun dogal yurume hizidir (iskelet olcegiyle metreye cevrilir).
	if clip_name.is_empty() or animator == null or skeleton == null:
		return 0.0
	var animation: Animation = animator.get_animation(clip_name)
	if animation == null or animation.length <= 0.0:
		return 0.0
	for track_index in range(animation.get_track_count()):
		if animation.track_get_type(track_index) != Animation.TYPE_POSITION_3D:
			continue
		if not String(animation.track_get_path(track_index).get_concatenated_subnames()).to_lower().ends_with("hips"):
			continue
		var start: Vector3 = animation.position_track_interpolate(track_index, 0.0)
		var finish: Vector3 = animation.position_track_interpolate(track_index, animation.length)
		var travel := Vector2(finish.x - start.x, finish.z - start.z).length()
		var unit_scale := skeleton.global_transform.basis.get_scale().x
		return travel * unit_scale / animation.length
	return 0.0

func _locomotion_playback_speed(target: String, sprinting: bool) -> float:
	# Animasyon hizi = hareket hizi / klibin kendi hizi -> ayak kaymasi yok.
	if target == walk_clip and walk_clip_speed > 0.1:
		return clampf(WALK_SPEED / walk_clip_speed, 0.6, 2.0)
	if target == run_clip:
		var move_speed := RUN_SPEED if sprinting else WALK_SPEED
		if run_clip_speed > 0.1:
			return clampf(move_speed / run_clip_speed, 0.4, 2.0)
		return 1.0 if sprinting else 0.65
	return 1.0

func _flatten_upward_root_motion(animation: Animation) -> void:
	# Ziplama yuksekligini fizik (CharacterBody3D) uretir. Klipteki kalca
	# yukselmesi kalirsa karakter iki kat ziplar; comelme/inis dususleri kalir.
	if animation == null:
		return
	for track_index in range(animation.get_track_count()):
		if animation.track_get_type(track_index) != Animation.TYPE_POSITION_3D:
			continue
		if not String(animation.track_get_path(track_index).get_concatenated_subnames()).to_lower().ends_with("hips"):
			continue
		var key_count := animation.track_get_key_count(track_index)
		if key_count == 0:
			continue
		var standing: Vector3 = animation.track_get_key_value(track_index, 0)
		for key_index in range(key_count):
			var value: Vector3 = animation.track_get_key_value(track_index, key_index)
			if value.y > standing.y:
				value.y = standing.y
				animation.track_set_key_value(track_index, key_index, value)



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
	if is_dead or (ui != null and ui.is_open):
		return
	if active_tool == "place":
		_place_campfire()
		return
	if active_tool != "axe" and active_tool != "pickaxe":
		return
	if animator == null or attack_clip.is_empty() or attack_remaining > 0.0 or not jump_phase.is_empty():
		return
	var animation := animator.get_animation(attack_clip)
	if animation == null:
		return
	attack_remaining = animation.length / ATTACK_PLAYBACK_SPEED
	current_animation_state = "Attack"
	animator.speed_scale = ATTACK_PLAYBACK_SPEED
	animator.play(attack_clip, 0.05)
	# Stationary axe swings should face the tree/camera direction as well.
	visuals.rotation.y = yaw + PI + deg_to_rad(character_facing_offset)
	pending_chop_target = _nearest_choppable_tree() if active_tool == "axe" else _nearest_mineable_rock()
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
	if is_dead:
		current_animation_state = "Death"
		return
	if not jump_phase.is_empty() and not jump_clip.is_empty() and animator != null:
		# Ziplama klibi kendi zamanlamasiyla oynar; inisten sonra hareket
		# basladiginda veya toparlanma bitince normal animasyona donulur.
		var clip_time := animator.current_animation_position if animator.current_animation == jump_clip else 0.0
		if jump_phase == "land" and (moving or clip_time >= JUMP_CLIP_RECOVERED):
			jump_phase = ""
		else:
			current_animation_state = "Jump" if jump_phase != "land" else "Landing"
			return
	# Brief losses of floor contact on uneven ground should not rewind the stride.
	ungrounded_time = 0.0 if player.is_on_floor() else ungrounded_time + delta
	var airborne := ungrounded_time >= FALL_POSE_DELAY
	var target := ""
	if airborne and not jump_clip.is_empty():
		# Ziplamadan dusme (kenardan kayma): ziplama klibinin dusus pozu.
		if animator != null and animator.current_animation != jump_clip:
			animator.play(jump_clip, 0.2)
			animator.seek(1.12, true)
		if animator != null:
			animator.speed_scale = 0.0
		current_animation_state = "Fall"
		return
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
			animator.speed_scale = _locomotion_playback_speed(target, sprinting)
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
	# Char1 FBX mesh'i oyun boyuna normalize ediliyor. Ayni olcek el kemigine
	# eklenen ekipmana da uygulanir; karsilastirma yapmadan alet ~1 cm kalir.
	var mount: Node3D = visuals
	var hand_bone := ""
	if skeleton != null:
		for bone_index in range(skeleton.get_bone_count()):
			var possible_name := String(skeleton.get_bone_name(bone_index))
			var compact_name := possible_name.to_lower().replace("_", "").replace(":", "").replace(".", "").replace("-", "").replace(" ", "")
			if compact_name.ends_with("righthand"):
				hand_bone = possible_name
				break
		if not hand_bone.is_empty():
			var attachment := BoneAttachment3D.new()
			attachment.name = "AxeRightHand"
			attachment.bone_name = hand_bone
			skeleton.add_child(attachment)
			mount = attachment
	axe_attachment = mount
	equipped_axe = _make_tool(mount, "hand_axe", "StarterAxe", 0.80)
	if equipped_axe == null:
		# Meshy balta yuklenemezse prosedurel balta kullanilir.
		equipped_axe = AXE_SCRIPT.new()
		equipped_axe.name = "StarterAxe"
		mount.add_child(equipped_axe)
		_place_tool(mount, equipped_axe)
	equipped_pickaxe = _make_tool(mount, "pickaxe", "StarterPickaxe", 0.85)
	torch = TORCH_SCRIPT.new()
	torch.name = "HandTorch"
	torch.set_meta("blade_sign", 1.0)
	mount.add_child(torch)
	_place_tool(mount, torch)
	torch.visible = false
	_make_placement_ghost()
	if mount is BoneAttachment3D:
		var grip_modifier := HAND_GRIP_SCRIPT.new()
		grip_modifier.name = "RightHandGrip"
		skeleton.add_child(grip_modifier)
		hand_grip = grip_modifier
	print("Ashvale equipped tools: mount=", hand_bone if not hand_bone.is_empty() else "fallback", " axe=", equipped_axe.get_meta("model_key", "procedural"), " pickaxe=", equipped_pickaxe != null, " world_scale=", equipped_axe.global_transform.basis.get_scale())

func _make_tool(mount: Node3D, model_key: String, tool_name: String, length: float) -> Node3D:
	var model := MODEL_LIBRARY.instantiate(model_key, length)
	if model == null:
		return null
	var grip: Dictionary = TOOL_GRIPS.get(model_key, {})
	var tool := Node3D.new()
	tool.name = tool_name
	tool.set_meta("model_key", model_key)
	tool.set_meta("blade_sign", float(grip.get("blade_sign", 1.0)))
	# Aracin orijini = elin kavradigi nokta. Sap ekseni X=Z=0 cizgisine,
	# kavrama yuksekligi y=0'a tasinir (model tabani y=0'da geliyor).
	model.position.x -= float(grip.get("handle_x", 0.0)) * length
	model.position.y -= float(grip.get("grip_height", 0.16)) * length
	tool.add_child(model)
	mount.add_child(tool)
	_place_tool(mount, tool)
	return tool

func _hand_bone_offset(hand_index: int, suffix: String) -> Vector3:
	# Parmak kemiginin dinlenme konumu, el kemiginin yerel uzayinda.
	var hand_rest := skeleton.get_bone_global_rest(hand_index)
	for bone_index in range(skeleton.get_bone_count()):
		var compact_name := String(skeleton.get_bone_name(bone_index)).to_lower().replace("_", "").replace(":", "")
		if compact_name.ends_with(suffix):
			return hand_rest.affine_inverse() * skeleton.get_bone_global_rest(bone_index).origin
	return Vector3.ZERO

func _place_tool(mount: Node3D, tool: Node3D) -> void:
	# Mount her rigde farkli unit-scale tasiyabilir (cm -> metre). Alet
	# dunya koordinatlarinda gercek boyunda kalmali ve el ile hareket etmeli.
	var mount_scale := mount.global_transform.basis.get_scale()
	var inherited_scale := maxf((mount_scale.x + mount_scale.y + mount_scale.z) / 3.0, 0.0001)
	var unit_correction := 1.0 / inherited_scale
	if not mount is BoneAttachment3D:
		tool.scale = Vector3.ONE * unit_correction
		tool.position = Vector3(0.43, 1.15, -0.20) * unit_correction
		tool.rotation_degrees = Vector3(0, -12, -24)
		return
	# Kavrama el iskeletinden hesaplanir: sap avucun icinden isaret->serce
	# parmak dogrultusunda gecer, alet basi basparmak tarafinda kalir,
	# agiz parmaklarin baktigi yone (vurus yonune) bakar.
	var hand_index := skeleton.find_bone((mount as BoneAttachment3D).bone_name)
	var index_knuckle := _hand_bone_offset(hand_index, "righthandindex1")
	var pinky_knuckle := _hand_bone_offset(hand_index, "righthandpinky1")
	var middle_knuckle := _hand_bone_offset(hand_index, "righthandmiddle1")
	var thumb_root := _hand_bone_offset(hand_index, "righthandthumb1")
	var finger_dir := middle_knuckle.normalized() if middle_knuckle.length() > 0.0001 else Vector3.UP
	var handle_dir := index_knuckle - pinky_knuckle
	handle_dir = (handle_dir - finger_dir * handle_dir.dot(finger_dir)).normalized()
	if handle_dir.length() < 0.5:
		handle_dir = Vector3.RIGHT
	var palm_dir := Vector3(0, 0, 1.0 if thumb_root.z >= 0.0 else -1.0)
	palm_dir = (palm_dir - finger_dir * palm_dir.dot(finger_dir) - handle_dir * palm_dir.dot(handle_dir)).normalized()
	var blade_sign := float(tool.get_meta("blade_sign", 1.0))
	var x_axis := finger_dir * blade_sign
	var y_axis := handle_dir
	var z_axis := x_axis.cross(y_axis).normalized()
	# Kavrama noktasi: avuc ortasi, parmak koklerinden biraz geride ve
	# kivrilan parmaklarin olusturdugu halkanin icinde (avucun onunde).
	var knuckle_center := (index_knuckle + pinky_knuckle) * 0.5
	var grip_point := knuckle_center * GRIP_ALONG_PALM + palm_dir * (GRIP_PALM_OFFSET * unit_correction)
	tool.transform = Transform3D(Basis(x_axis, y_axis, z_axis).scaled(Vector3.ONE * unit_correction), grip_point)


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
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_respawn()
	if is_dead:
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			yaw -= event.relative.x * 0.003
			pitch = clampf(pitch - event.relative.y * 0.003, -0.8, 0.35)
			camera_pivot.rotation = Vector3(pitch, yaw, 0)
		return
	if ui != null and ui.is_open:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_TAB, KEY_ESCAPE]:
			_toggle_inventory()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_T:
				atmosphere.advance_hours(1.0)
			KEY_TAB:
				_toggle_inventory()
				get_viewport().set_input_as_handled()
				return
			KEY_H:
				ui.toggle_help()
			KEY_F3:
				ui.toggle_debug()
			KEY_E:
				var fire := _closest_fire(3.0)
				if fire != null and _nearest_resource() == null and _nearest_fern() == null:
					_refuel(fire)
				else:
					_collect_resource()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
				_select_slot(int(event.keycode - KEY_1))
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

func _toggle_inventory() -> void:
	if ui == null or is_dead:
		return
	var opened: bool = ui.toggle_inventory()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if opened else Input.MOUSE_MODE_CAPTURED

func _begin_jump() -> void:
	if jump_clip.is_empty() or animator == null:
		# Klip yoksa eski davranis: aninda zipla.
		player.velocity.y = JUMP_VELOCITY
		return
	jump_phase = "crouch"
	jump_timer = JUMP_TAKEOFF_DELAY
	animator.play(jump_clip, 0.08)
	animator.seek(JUMP_CLIP_START, true)
	animator.speed_scale = JUMP_PLAYBACK_SPEED

func _advance_jump(delta: float) -> void:
	match jump_phase:
		"crouch":
			jump_timer -= delta
			if jump_timer <= 0.0:
				player.velocity.y = JUMP_VELOCITY
				jump_phase = "air"
				jump_timer = 0.0
		"air":
			jump_timer += delta
			if jump_timer > 0.1 and player.is_on_floor() and player.velocity.y <= 0.0:
				jump_phase = "land"
				if animator != null and animator.current_animation == jump_clip:
					animator.seek(maxf(animator.current_animation_position, JUMP_CLIP_LANDING), true)

func _has_mining_tool() -> bool:
	return inventory.count("copper_pickaxe") > 0 or inventory.count("iron_pickaxe") > 0

func _update_expedition() -> void:
	if not survived_first_night or is_dead:
		return
	var old_stage := expedition_stage
	match expedition_stage:
		Expedition.FIND:
			if player.global_position.distance_to(MINE.ENTRANCE) < 10:
				expedition_stage = Expedition.RETURN
				ui.toast("Terk edilmiş madeni keşfettin.")
		Expedition.RETURN:
			if player.global_position.distance_to(CAMP_POSITION) < 8 and (copper >= 5 or _has_mining_tool()):
				expedition_stage = Expedition.MINE_IRON
		Expedition.MINE_IRON:
			if mine_iron_collected:
				expedition_stage = Expedition.COMPLETE
				ui.toast("Maden seferi tamamlandı.")
	if old_stage != expedition_stage:
		_schedule_checkpoint()

func _expedition_hint() -> String:
	match expedition_stage:
		Expedition.FIND:
			return "Kuzeydeki maden kulesine ulaş · %d m" % ceili(player.position.distance_to(MINE.ENTRANCE))
		Expedition.RETURN:
			if copper < 5 and not _has_mining_tool():
				return "Girişten bakır topla · %d/5" % copper
			return "Bakırı kampa götür · %d m" % ceili(player.position.distance_to(CAMP_POSITION))
		Expedition.MINE_IRON:
			if not _has_mining_tool():
				return "Tab ile bakır kazma üret · 5 bakır, 3 odun, 1 ip"
			return "Galerideki demiri çıkar · Meşaleyle yolu bul."
	return ""

func _update_gallery_camera() -> void:
	var camera: Camera3D = camera_pivot.get_node("Camera")
	var desired := Vector3(0, 1, camera_distance)
	if camera_pivot.global_position.distance_squared_to(MINE.ENTRANCE) < 45 * 45:
		var ray := PhysicsRayQueryParameters3D.create(camera_pivot.global_position, camera_pivot.to_global(desired), 4)
		var hit := get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty():
			var reach := maxf(0.15, camera_pivot.global_position.distance_to(hit.position) - 0.22)
			desired = desired.normalized() * reach
	camera.position = desired

func _closest_fire(radius: float, lit_only := false) -> Node3D:
	var closest: Node3D
	for fire in campfires:
		var distance := fire.global_position.distance_to(player.global_position)
		if distance <= radius and (not lit_only or fire.fuel > 0):
			radius = distance
			closest = fire
	return closest

func _refuel(fire: Node3D) -> void:
	if fire.fuel > fire.MAX_FUEL - fire.WOOD_SECONDS:
		ui.toast("Ateşte bir odunluk yer yok.")
	elif inventory.remove("wood", 1):
		fire.set_fuel(fire.fuel + fire.WOOD_SECONDS)
		ui.toast("Ateşe odun eklendi.", "wood")
	else:
		ui.toast("Ateşi beslemek için 1 odun gerekli.")

func _night_now() -> bool:
	return atmosphere.hour >= atmosphere.SUNSET_HOUR or atmosphere.hour < atmosphere.SUNRISE_HOUR

func _advance_survival(delta: float) -> void:
	var night := _night_now()
	if night != night_started:
		night_started = night
		if night:
			night_failed = is_dead
		elif not night_failed and not is_dead and not survived_first_night:
			survived_first_night = true
			ui.toast("İlk geceyi atlattın!")
		_schedule_checkpoint()
	if is_dead:
		return
	var warming := _closest_fire(5.0, true) != null
	var evening: bool = atmosphere.hour >= 17.0 and not night
	if warming:
		warmth = minf(100, warmth + delta * 2.0)
	elif night:
		warmth = maxf(0, warmth - delta * 0.8)
	elif evening:
		warmth = move_toward(warmth, 55, delta * 0.25)
	else:
		warmth = minf(100, warmth + delta)
	if night and warmth <= 0 and not warming:
		_take_damage(delta * 1.5)

func _update_health(delta: float) -> void:
	if is_dead:
		return
	burning = _closest_fire(FIRE_RADIUS, true) != null
	if burning:
		_take_damage(FIRE_DAMAGE_PER_SECOND * delta)
	else:
		time_since_damage += delta
		if time_since_damage > HEALTH_REGEN_DELAY:
			health = minf(health + HEALTH_REGEN_PER_SECOND * delta, MAX_HEALTH)

func _take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	time_since_damage = 0.0
	if health <= 0.0:
		_die()

func _die() -> void:
	if _night_now():
		night_failed = true
	_schedule_checkpoint()
	is_dead = true
	burning = false
	jump_phase = ""
	attack_remaining = 0.0
	pending_chop_target = null
	player.velocity = Vector3.ZERO
	if animator != null and not death_clip.is_empty():
		animator.speed_scale = 1.0
		animator.play(death_clip, 0.12)
	current_animation_state = "Death"
	print("Ashvale: oyuncu oldu")
	if hud != null:
		_update_hud()

func _respawn() -> void:
	if not is_dead:
		return
	is_dead = false
	warmth = 100.0
	_schedule_checkpoint()
	health = MAX_HEALTH
	stamina = 100.0
	sprint_exhausted = false
	ungrounded_time = 0.0
	time_since_damage = 99.0
	player.global_position = SPAWN_POSITION
	player.velocity = Vector3.ZERO
	if animator != null and not idle_clip.is_empty():
		animator.speed_scale = 1.0
		animator.play(idle_clip, 0.2)
	current_animation_state = "Idle"
	if hud != null:
		_update_hud()

func _physics_process(delta: float) -> void:
	var input := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	).normalized()
	var inventory_open: bool = ui != null and ui.is_open
	if inventory_open or is_dead or attack_remaining > 0.0:
		# Olurken ve balta/kazma savrulurken oyuncu yerinde kalir.
		input = Vector2.ZERO
	var direction := Basis(Vector3.UP, yaw) * Vector3(input.x, 0, input.y)
	if stamina <= 1.0:
		sprint_exhausted = true
	elif stamina >= SPRINT_RECOVERY_STAMINA:
		sprint_exhausted = false
	var sprint := Input.is_physical_key_pressed(KEY_SHIFT) and not sprint_exhausted and input.length_squared() > 0.01
	stamina = clampf(stamina + (-22.0 if sprint else 16.0) * delta, 0.0, 100.0)
	var speed := RUN_SPEED if sprint else WALK_SPEED
	player.velocity.x = direction.x * speed
	player.velocity.z = direction.z * speed
	if not player.is_on_floor():
		player.velocity.y -= GRAVITY * delta
	elif not inventory_open and jump_phase.is_empty() and not is_dead and attack_remaining <= 0.0 and Input.is_physical_key_pressed(KEY_SPACE):
		_begin_jump()
	elif jump_phase != "air":
		player.velocity.y = -0.1
	_advance_jump(delta)
	player.move_and_slide()
	var pos := player.global_position
	if pos.y < -3.0:
		player.global_position = SPAWN_POSITION
		player.velocity = Vector3.ZERO
		jump_phase = ""
	else:
		player.global_position = Vector3(clampf(pos.x, -WORLD_LIMIT, WORLD_LIMIT), pos.y, clampf(pos.z, -WORLD_LIMIT, WORLD_LIMIT))
	_advance_survival(delta)
	_update_expedition()
	_update_health(delta)
	if direction.length_squared() > 0.01:
		visuals.rotation.y = lerp_angle(visuals.rotation.y, atan2(direction.x, direction.z) + deg_to_rad(character_facing_offset), delta * 10.0)
	_update_character_animation(delta, input.length_squared() > 0.01, sprint)
	_advance_axe_impact(delta)
	_update_placement()
	camera_pivot.global_position = camera_pivot.global_position.lerp(player.global_position + Vector3(0, 1.5, 0), minf(delta * 8.0, 1.0))
	_update_gallery_camera()
	hud_elapsed += delta
	if hud_elapsed >= 0.1:
		hud_elapsed = 0.0
		_update_hud()
	if session_active:
		save_elapsed += delta
		if save_elapsed >= 30.0:
			save_elapsed = 0.0
			_checkpoint()
