extends Node3D

# Kazma ile kirilan kaya / cevher. Son vurusta yere toplanabilir parcalar birakir.
signal resources_dropped(items: Array)

const SHAKE_SECONDS := 0.18
const CHUNK_COLORS := {
	"stone": Color("#8a8d86"),
	"copper": Color("#c06a3a"),
	"iron": Color("#5d6166"),
}

@export var resource_kind := "stone"
@export var max_hits := 3
@export var drop_count := 2

var hits_taken: int = 0
var is_depleted: bool = false

func take_pickaxe_hit(attacker_world_position: Vector3) -> bool:
	if is_depleted:
		return false
	hits_taken += 1
	var towards_attacker := attacker_world_position - global_position
	towards_attacker.y = 0.0
	towards_attacker = towards_attacker.normalized() if towards_attacker.length_squared() > 0.001 else Vector3.FORWARD
	_emit_chips(towards_attacker)
	var model := get_node_or_null("Model") as Node3D
	if hits_taken >= max_hits:
		_deplete(towards_attacker)
	elif model != null:
		var rest := model.position
		var shake := create_tween()
		shake.tween_property(model, "position", rest + towards_attacker * -0.06, SHAKE_SECONDS * 0.4)
		shake.tween_property(model, "position", rest, SHAKE_SECONDS * 0.6)
	return true

func _deplete(towards_attacker: Vector3) -> void:
	is_depleted = true
	set_meta("resource_type", "spent_rock")
	var body := get_node_or_null("RockBody")
	if body != null:
		body.queue_free()
	var parent_node := get_parent()
	var drops: Array[Node3D] = []
	if parent_node != null:
		for index in range(drop_count):
			var drop := _make_chunk(index)
			parent_node.add_child(drop)
			var side := towards_attacker.rotated(Vector3.UP, (float(index) - 0.5 * float(drop_count - 1)) * 0.9)
			drop.global_position = global_position + side * 0.9
			drop.position.y = 0.12
			drops.append(drop)
	resources_dropped.emit(drops)
	var vanish := create_tween()
	vanish.tween_property(self, "scale", Vector3(1.05, 0.05, 1.05), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	vanish.tween_callback(queue_free)

func _make_chunk(index: int) -> Node3D:
	var pickup := Node3D.new()
	pickup.name = "%sChunk_%d" % [resource_kind.capitalize(), index]
	pickup.set_meta("resource_type", resource_kind + "_drop")
	pickup.set_meta("amount", 1)
	var piece := MeshInstance3D.new()
	piece.name = "Chunk"
	var shape := SphereMesh.new()
	shape.radial_segments = 6
	shape.rings = 3
	shape.radius = 0.2
	shape.height = 0.28
	piece.mesh = shape
	piece.rotation = Vector3(0.4 * index, 1.1 * index, 0.2)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = CHUNK_COLORS.get(resource_kind, Color.GRAY)
	mat.roughness = 0.8
	mat.metallic = 0.0 if resource_kind == "stone" else 0.55
	piece.material_override = mat
	pickup.add_child(piece)
	return pickup

func _emit_chips(towards_attacker: Vector3) -> void:
	for index in range(3):
		var chip := MeshInstance3D.new()
		chip.name = "RockChip"
		var bit := BoxMesh.new()
		bit.size = Vector3(0.07, 0.06, 0.05)
		chip.mesh = bit
		var mat := StandardMaterial3D.new()
		mat.albedo_color = CHUNK_COLORS.get(resource_kind, Color.GRAY)
		chip.material_override = mat
		chip.position = Vector3(0, 0.6, 0) + towards_attacker * 0.5
		add_child(chip)
		var side := towards_attacker.rotated(Vector3.UP, (float(index) - 1.0) * 0.8)
		var flight := create_tween()
		flight.tween_property(chip, "position", chip.position + side * 0.5 + Vector3(0, 0.25, 0), 0.18)
		flight.tween_property(chip, "position:y", 0.03, 0.2)
		flight.tween_callback(chip.queue_free)
