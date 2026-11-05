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

var hits_taken: int = 0
var is_falling: bool = false
var _fall_origin: Quaternion = Quaternion.IDENTITY
var _fall_axis: Vector3 = Vector3.RIGHT
var _fall_vector: Vector3 = Vector3.FORWARD
var _original_world_position: Vector3 = Vector3.ZERO

func take_axe_hit(attacker_world_position: Vector3) -> bool:
	if is_falling:
		return false
	var towards_attacker := attacker_world_position - global_position
	towards_attacker.y = 0.0
	if towards_attacker.length_squared() < 0.001:
		towards_attacker = Vector3.FORWARD
	towards_attacker = towards_attacker.normalized()
	hits_taken += 1
	_create_cut_mark(towards_attacker)
	_emit_splinters(towards_attacker)
	if hits_taken >= MAX_HITS:
		_begin_fall(-towards_attacker)
	else:
		var base_angle: float = rotation.z
		var wobble := create_tween()
		wobble.tween_property(self, "rotation:z", base_angle + 0.035, 0.07)
		wobble.tween_property(self, "rotation:z", base_angle - 0.022, 0.08)
		wobble.tween_property(self, "rotation:z", base_angle, 0.09)
	return true

func _create_cut_mark(towards_attacker: Vector3) -> void:
	var facing_local := global_transform.basis.inverse() * towards_attacker
	facing_local.y = 0.0
	facing_local = facing_local.normalized()
	var notch := Node3D.new()
	notch.name = "CutMark_%d" % hits_taken
	notch.position = Vector3(0, 1.12 + float(hits_taken - 1) * 0.16, 0)
	notch.rotation.y = atan2(facing_local.x, facing_local.z)
	add_child(notch)
	var wound := MeshInstance3D.new()
	var cut := BoxMesh.new()
	cut.size = Vector3(0.43 + float(hits_taken) * 0.05, 0.115, 0.055)
	wound.mesh = cut
	wound.position = Vector3(0, 0, 0.62)
	wound.material_override = _material(CUT_WOOD)
	notch.add_child(wound)

func _emit_splinters(towards_attacker: Vector3) -> void:
	for index in range(4):
		var fragment := MeshInstance3D.new()
		fragment.name = "ChopSplinter"
		var bit := BoxMesh.new()
		bit.size = Vector3(0.045, 0.085 + float(index) * 0.028, 0.035)
		fragment.mesh = bit
		fragment.material_override = _material(SPLINTER)
		fragment.position = Vector3(0, 1.20, 0) + towards_attacker * 0.60
		add_child(fragment)
		var angle := float(index) * TAU / 4.0
		var side := Vector3(cos(angle), 0, sin(angle))
		var end_point := fragment.position + side * 0.55 + Vector3(0, 0.13 + float(index % 2) * 0.18, 0)
		fragment.rotation = Vector3(angle * 0.5, angle, angle * 0.4)
		var flight := create_tween()
		flight.tween_property(fragment, "position", end_point, 0.24)
		flight.tween_property(fragment, "position:y", 0.03, 0.21)
		flight.tween_callback(fragment.queue_free)

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
	var log := CylinderMesh.new()
	log.radial_segments = 7
	log.height = 0.76
	log.top_radius = 0.19
	log.bottom_radius = 0.21
	var cylinder := MeshInstance3D.new()
	cylinder.name = "SplitLog"
	cylinder.mesh = log
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

func _material(tint: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = tint
	result.roughness = 0.96
	return result
