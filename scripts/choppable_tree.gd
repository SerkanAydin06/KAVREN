extends Node3D

# Controls-driven tree felling: three hits, not procedural mesh fracture.
# Meshy model remains unchanged; this Node3D owns the imported mesh and collision.
signal wood_dropped(items: Array)

const MAX_HITS := 3
const FALL_SECONDS := 0.95
const WOOD_PIECES := 3
const BARK := Color("#493325")
const BARK_HIGHLIGHT := Color("#755039")
const CUT_WOOD := Color("#d6ad74")
const SPLINTER := Color("#b27d4f")
const MODEL_LIBRARY := preload("res://scripts/model_library.gd")
const STUMP_HEIGHT := 0.75
const CHOP_NOTCH_SCRIPT := preload("res://scripts/chop_notch.gd")
# Balta darbesinin yerden yuksekligi (oyuncunun bel hizasi).
const CHOP_HEIGHT := 0.95

static var _triangle_cache: Dictionary = {}
var _notch: Node3D = null
var _notch_surface := Vector3.ZERO
var _notch_outward := Vector3.FORWARD

var hits_taken: int = 0
var damage_taken: float = 0.0
var is_falling: bool = false
var _fall_origin: Quaternion = Quaternion.IDENTITY
var _fall_axis: Vector3 = Vector3.RIGHT
var _fall_vector: Vector3 = Vector3.FORWARD
var _original_world_position: Vector3 = Vector3.ZERO

# power: baltanin darbe gucu (Tas 1, Bakir 1.5, Demir 3). Agac MAX_HITS hasarda devrilir.
func take_axe_hit(attacker_world_position: Vector3, power: float = 1.0) -> bool:
	if is_falling:
		return false
	var towards_attacker := attacker_world_position - global_position
	towards_attacker.y = 0.0
	if towards_attacker.length_squared() < 0.001:
		towards_attacker = Vector3.FORWARD
	towards_attacker = towards_attacker.normalized()
	hits_taken += 1
	damage_taken += maxf(power, 0.1)
	var impact := _find_impact(towards_attacker)
	_update_notch(impact)
	_emit_splinters(impact)
	if damage_taken >= float(MAX_HITS) - 0.001:
		_begin_fall(-towards_attacker)
	else:
		var base_angle: float = rotation.z
		var wobble := create_tween()
		wobble.tween_property(self, "rotation:z", base_angle + 0.035, 0.07)
		wobble.tween_property(self, "rotation:z", base_angle - 0.022, 0.08)
		wobble.tween_property(self, "rotation:z", base_angle, 0.09)
	return true

# Darbe noktasi: oyuncudan govde eksenine yatay isin, agacin GERCEK mesh
# yuzeyine. Mesh verisi yoksa (headless) carpisma silindiri kullanilir.
func _find_impact(towards_attacker: Vector3) -> Dictionary:
	var axis := global_position + Vector3(0, CHOP_HEIGHT, 0)
	var origin := axis + towards_attacker * 4.0
	var direction := -towards_attacker
	var best := {}
	var best_distance := INF
	for node in find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh == null or mesh_node is CHOP_NOTCH_SCRIPT or String(mesh_node.name).begins_with("Chop"):
			continue
		var triangles := _triangle_mesh(mesh_node.mesh)
		if triangles == null:
			continue
		var world_to_mesh := mesh_node.global_transform.affine_inverse()
		var hit: Dictionary = triangles.intersect_ray(world_to_mesh * origin, (world_to_mesh.basis * direction).normalized())
		if hit.is_empty():
			continue
		var world_point: Vector3 = mesh_node.global_transform * Vector3(hit["position"])
		var distance := origin.distance_to(world_point)
		if distance < best_distance:
			best_distance = distance
			var world_normal: Vector3 = (mesh_node.global_transform.basis.inverse().transposed() * Vector3(hit["normal"])).normalized()
			best = {"point": world_point, "normal": world_normal}
	if best.is_empty():
		var radius := 0.5
		var collision := get_node_or_null("TrunkBody/CollisionShape3D") as CollisionShape3D
		if collision == null:
			collision = get_node_or_null("CollisionBody/CollisionShape3D") as CollisionShape3D
		if collision != null and collision.shape is CylinderShape3D:
			radius = (collision.shape as CylinderShape3D).radius
		best = {"point": axis + towards_attacker * radius, "normal": towards_attacker}
	# Kesik her zaman yatay; yuzey normali sadece yatay yonu duzeltir.
	var outward: Vector3 = best["normal"]
	outward.y = 0.0
	if outward.length_squared() < 0.01 or outward.dot(towards_attacker) < 0.2:
		outward = towards_attacker
	best["outward"] = outward.normalized()
	var radial: Vector3 = Vector3(best["point"]) - axis
	radial.y = 0.0
	best["radius"] = clampf(radial.length(), 0.15, 1.6)
	return best

static func _triangle_mesh(mesh: Mesh) -> TriangleMesh:
	var key := mesh.get_instance_id()
	if _triangle_cache.has(key):
		return _triangle_cache[key]
	var triangles: TriangleMesh = null
	if mesh.get_faces().size() >= 3:
		triangles = mesh.generate_triangle_mesh()
	_triangle_cache[key] = triangles
	return triangles

func _update_notch(impact: Dictionary) -> void:
	if _notch == null:
		# Gercek derinlikli oyulmus centik. (Decal denendi: duz ve soluk kaldi.)
		_notch = CHOP_NOTCH_SCRIPT.new()
		_notch.name = "ChopNotch"
		add_child(_notch)
		_notch.configure(float(impact["radius"]))
		_notch_surface = Vector3(impact["point"])
		_notch_outward = Vector3(impact["outward"])
		_notch.global_transform = Transform3D(Basis.looking_at(-_notch_outward, Vector3.UP), _notch_surface)
	_notch.set_progress(minf(damage_taken / float(MAX_HITS), 1.0))

func _emit_splinters(impact: Dictionary) -> void:
	var start: Vector3 = Vector3(impact["point"]) + Vector3(impact["outward"]) * 0.05
	var outward: Vector3 = impact["outward"]
	var ground_y := global_position.y + 0.03
	for index in range(6):
		var fragment := MeshInstance3D.new()
		fragment.name = "ChopSplinter"
		var bit := BoxMesh.new()
		var is_bark := index % 3 == 0
		bit.size = Vector3(0.03 + 0.01 * (index % 2), 0.07 + float(index) * 0.018, 0.02)
		fragment.mesh = bit
		fragment.material_override = _material(BARK if is_bark else SPLINTER)
		get_parent().add_child(fragment)
		fragment.global_position = start
		var side := outward.rotated(Vector3.UP, (float(index) - 2.5) * 0.32)
		var apex := start + side * (0.35 + 0.08 * index) + Vector3(0, 0.18 + 0.05 * (index % 3), 0)
		var landing := Vector3(apex.x, ground_y, apex.z) + side * 0.25
		fragment.rotation = Vector3(index * 0.7, index * 1.3, index * 0.4)
		var flight := create_tween()
		flight.set_parallel(true)
		flight.tween_property(fragment, "global_position", apex, 0.16).set_ease(Tween.EASE_OUT)
		flight.tween_property(fragment, "rotation", fragment.rotation + Vector3(4.0, 2.0, 3.0), 0.5)
		flight.chain().tween_property(fragment, "global_position", landing, 0.26).set_ease(Tween.EASE_IN)
		flight.chain().tween_interval(1.4)
		flight.chain().tween_property(fragment, "scale", Vector3.ONE * 0.01, 0.3)
		flight.chain().tween_callback(fragment.queue_free)

func _begin_fall(fall_world_direction: Vector3) -> void:
	is_falling = true
	set_meta("resource_type", "spent_tree")
	_original_world_position = global_position
	_fall_vector = fall_world_direction.normalized()
	var local_direction := global_transform.basis.inverse() * _fall_vector
	local_direction.y = 0.0
	_fall_axis = Vector3.UP.cross(local_direction.normalized()).normalized()
	_fall_origin = quaternion
	_add_stump()
	var sequence := create_tween()
	sequence.tween_method(_set_fall_progress, 0.0, 1.0, FALL_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	sequence.tween_callback(_finish_fall)

func _set_fall_progress(progress: float) -> void:
	quaternion = _fall_origin * Quaternion(_fall_axis, progress * 1.52)

func _finish_fall() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	var drops: Array[Node3D] = []
	for index in range(WOOD_PIECES):
		var drop := _make_wood_piece(index)
		parent_node.add_child(drop)
		drop.global_position = _original_world_position + _fall_vector * (1.0 + float(index) * 0.64)
		drop.position.y = 0.13
		drops.append(drop)
	wood_dropped.emit(drops)
	queue_free()

func _make_wood_piece(index: int) -> Node3D:
	var pickup := Node3D.new()
	pickup.name = "WoodPickup_%d" % index
	pickup.set_meta("resource_type", "wood_drop")
	pickup.set_meta("wood_amount", 1)
	var log_mesh := CylinderMesh.new()
	log_mesh.radial_segments = 7
	log_mesh.height = 0.76
	log_mesh.top_radius = 0.19
	log_mesh.bottom_radius = 0.21
	var cylinder := MeshInstance3D.new()
	cylinder.name = "SplitLog"
	cylinder.mesh = log_mesh
	cylinder.rotation.z = PI * 0.5
	cylinder.material_override = _material(BARK)
	pickup.add_child(cylinder)
	for sign_index in range(2):
		var end_face := CylinderMesh.new()
		end_face.radial_segments = 7
		end_face.height = 0.015
		end_face.top_radius = 0.185
		end_face.bottom_radius = 0.185
		var face := MeshInstance3D.new()
		face.name = "FreshCut_%d" % sign_index
		face.mesh = end_face
		face.rotation.z = PI * 0.5
		face.position.x = -0.384 if sign_index == 0 else 0.384
		face.material_override = _material(CUT_WOOD)
		pickup.add_child(face)
	pickup.rotation.y = float(index) * 1.15
	return pickup

func _add_stump() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	var stump := Node3D.new()
	stump.name = name + "_Stump"
	parent_node.add_child(stump)
	stump.global_position = global_position
	stump.rotation.y = rotation.y
	# Meshy kutuk modeli; yuklenemezse basit silindir kutuge duser.
	var stump_model := MODEL_LIBRARY.instantiate("tree_stump", STUMP_HEIGHT)
	if stump_model != null:
		stump.add_child(stump_model)
	else:
		_add_primitive_stump(stump)
	var body := StaticBody3D.new()
	body.name = "StumpBody"
	stump.add_child(body)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := CylinderShape3D.new()
	shape.height = 0.58
	shape.radius = 0.45
	collision.shape = shape
	collision.position.y = 0.29
	body.add_child(collision)

func _add_primitive_stump(stump: Node3D) -> void:
	var outer := CylinderMesh.new()
	outer.radial_segments = 9
	outer.height = 0.60
	outer.bottom_radius = 0.53
	outer.top_radius = 0.46
	var bark_mesh := MeshInstance3D.new()
	bark_mesh.name = "StumpBark"
	bark_mesh.mesh = outer
	bark_mesh.position.y = 0.30
	bark_mesh.material_override = _material(BARK_HIGHLIGHT)
	stump.add_child(bark_mesh)
	var cap := CylinderMesh.new()
	cap.radial_segments = 9
	cap.height = 0.022
	cap.top_radius = 0.45
	cap.bottom_radius = 0.45
	var top := MeshInstance3D.new()
	top.name = "FreshCutTop"
	top.mesh = cap
	top.position.y = 0.61
	top.material_override = _material(CUT_WOOD)
	stump.add_child(top)

func _material(tint: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = tint
	result.roughness = 0.96
	return result

func remaining_hits(power: float) -> int:
	return int(ceilf(maxf(float(MAX_HITS) - damage_taken, 0.0) / maxf(power, 0.1) - 0.001))
