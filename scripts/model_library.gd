extends RefCounted

# Ashvale Meshy model katalogu.
# Her model kendi klasorunde ayni duzende durur:
#   <klasor>/<ad>/<ad>.fbx
#   <klasor>/<ad>/<ad>_albedo.png  (zorunlu)
#   <klasor>/<ad>/<ad>_normal.png, _roughness.png, _metallic.png  (istege bagli)
# FBX icine gomulu dokular ice aktarimda atilir; PBR malzemesi buradan baglanir.
const MODELS := {
	"ancient_oak": "res://assets/environment/trees/ancient_oak",
	"emerald_pine": "res://assets/environment/trees/emerald_pine",
	"silverleaf_birch": "res://assets/environment/trees/silverleaf_birch",
	"twisted_elder": "res://assets/environment/trees/twisted_elder",
	"stone_boulder": "res://assets/environment/rocks/stone_boulder",
	"mossy_boulder": "res://assets/environment/rocks/mossy_boulder",
	"copper_ore": "res://assets/environment/ores/copper_ore",
	"iron_ore": "res://assets/environment/ores/iron_ore",
	"fern": "res://assets/environment/plants/fern",
	"tree_stump": "res://assets/environment/props/tree_stump",
	"hand_axe": "res://assets/tools/hand_axe",
	"pickaxe": "res://assets/tools/pickaxe",
}
# Yaprakli modellerin arka yuzleri de cizilmeli.
const DOUBLE_SIDED := ["ancient_oak", "emerald_pine", "silverleaf_birch", "twisted_elder", "fern"]

static var _materials: Dictionary = {}

static func model_path(key: String) -> String:
	return "%s/%s.fbx" % [MODELS.get(key, ""), key]

static func texture_path(key: String, channel: String) -> String:
	return "%s/%s_%s.png" % [MODELS.get(key, ""), key, channel]

static func load_scene(key: String) -> PackedScene:
	if not MODELS.has(key):
		push_warning("Ashvale: bilinmeyen model anahtari " + key)
		return null
	var path := model_path(key)
	if not ResourceLoader.exists(path):
		push_warning("Ashvale: model bulunamadi " + path)
		return null
	var resource: Resource = load(path)
	return resource as PackedScene

static func _texture(key: String, channel: String) -> Texture2D:
	var path := texture_path(key, channel)
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

# Ayni modelin tum kopyalari tek malzemeyi paylasir.
static func material(key: String) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var albedo := _texture(key, "albedo")
	if albedo == null:
		return null
	var result := StandardMaterial3D.new()
	result.resource_name = key
	result.albedo_texture = albedo
	var normal := _texture(key, "normal")
	if normal != null:
		result.normal_enabled = true
		result.normal_texture = normal
	var roughness := _texture(key, "roughness")
	result.roughness = 1.0 if roughness != null else 0.88
	if roughness != null:
		result.roughness_texture = roughness
	var metallic := _texture(key, "metallic")
	if metallic != null:
		result.metallic = 1.0
		result.metallic_texture = metallic
	if DOUBLE_SIDED.has(key):
		result.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = result
	return result

static func apply_material(model_root: Node, key: String) -> int:
	var shared := material(key)
	if shared == null:
		return 0
	var applied := 0
	for node in _all_nodes(model_root):
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			var mesh_node := node as MeshInstance3D
			for surface_index in range(mesh_node.mesh.get_surface_count()):
				mesh_node.set_surface_override_material(surface_index, shared)
				applied += 1
	return applied

# Agaca eklenmeden de calisir: yerel transformlari zincirleyerek sinirlari olcer.
static func measure_bounds(model_root: Node3D) -> AABB:
	var bounds := AABB()
	var found := false
	var pending: Array = [[model_root, Transform3D.IDENTITY]]
	while not pending.is_empty():
		var entry: Array = pending.pop_back()
		var node: Node = entry[0]
		var xf: Transform3D = entry[1]
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			var part: AABB = xf * (node as MeshInstance3D).mesh.get_aabb()
			bounds = part if not found else bounds.merge(part)
			found = true
		for child in node.get_children():
			if child is Node3D:
				pending.append([child, xf * (child as Node3D).transform])
			else:
				pending.append([child, xf])
	return bounds

# Modeli "Model" adli cocuk olarak doner. Yukseklik (veya fit_longest ile en uzun
# kenar) target_size metreye olceklenir, taban y=0 ve XZ merkezi orijindir.
static func instantiate(key: String, target_size: float, fit_longest := false) -> Node3D:
	var packed := load_scene(key)
	if packed == null:
		return null
	var instance := packed.instantiate()
	if not instance is Node3D:
		instance.queue_free()
		return null
	var model := instance as Node3D
	model.name = "Model"
	model.set_meta("model_key", key)
	apply_material(model, key)
	var bounds := measure_bounds(model)
	var source_extent := bounds.get_longest_axis_size() if fit_longest else bounds.size.y
	if source_extent > 0.0001:
		var uniform := target_size / source_extent
		model.scale = Vector3.ONE * uniform
		var center := bounds.get_center()
		model.position = Vector3(-center.x, -bounds.position.y, -center.z) * uniform
	return model

static func set_visibility_range(model_root: Node, end_distance: float, cast_shadows: bool) -> void:
	for node in _all_nodes(model_root):
		if node is GeometryInstance3D:
			var geometry := node as GeometryInstance3D
			geometry.visibility_range_end = end_distance
			geometry.visibility_range_end_margin = end_distance * 0.1
			geometry.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			if not cast_shadows:
				geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func triangle_count(model_root: Node) -> int:
	var total := 0
	for node in _all_nodes(model_root):
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			var mesh := (node as MeshInstance3D).mesh
			for surface_index in range(mesh.get_surface_count()):
				var indices: int = mesh.surface_get_array_index_len(surface_index)
				var vertices: int = mesh.surface_get_array_len(surface_index)
				total += floori((indices if indices > 0 else vertices) / 3.0)
	return total

static func _all_nodes(root_node: Node) -> Array[Node]:
	var result: Array[Node] = []
	var pending: Array[Node] = [root_node]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		result.append(current)
		for child in current.get_children():
			pending.append(child)
	return result
