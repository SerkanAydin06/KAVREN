extends Node3D

# Lightweight survival axe. Only a few primitive meshes, no costly rig or physics.
const GRIP := Color("#795038")
const METAL := Color("#697478")
const EDGE := Color("#b8bec0")

func _ready() -> void:
	var handle := CylinderMesh.new()
	handle.radial_segments = 8
	handle.top_radius = 0.032
	handle.bottom_radius = 0.038
	handle.height = 0.72
	_add_part("Handle", handle, Vector3(0, 0, 0), GRIP)
	var head := BoxMesh.new()
	head.size = Vector3(0.30, 0.22, 0.10)
	_add_part("AxeHead", head, Vector3(0.12, 0.27, 0), METAL)
	var edge := BoxMesh.new()
	edge.size = Vector3(0.06, 0.29, 0.106)
	_add_part("CuttingEdge", edge, Vector3(0.29, 0.27, 0), EDGE)
	var socket := CylinderMesh.new()
	socket.radial_segments = 8
	socket.height = 0.13
	socket.top_radius = 0.058
	socket.bottom_radius = 0.058
	_add_part("HeadSocket", socket, Vector3(0, 0.27, 0), METAL)

func _add_part(part_name: String, geometry: Mesh, local_pos: Vector3, tint: Color) -> void:
	var item := MeshInstance3D.new()
	item.name = part_name
	item.mesh = geometry
	item.position = local_pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.83
	item.material_override = mat
	add_child(item)
