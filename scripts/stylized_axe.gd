extends Node3D

# Compact stylized survival axe. Original FBX right-hand bone follows animation.
const GRIP := Color("#795038")
const GRIP_DARK := Color("#453025")
const METAL := Color("#5c6b70")
const EDGE := Color("#c0c5c3")

func _ready() -> void:
	var handle := CylinderMesh.new()
	handle.radial_segments = 8
	handle.top_radius = 0.036
	handle.bottom_radius = 0.046
	handle.height = 0.84
	_add_part("Handle", handle, Vector3(0, -0.07, 0), GRIP)
	for index in range(4):
		var grip_band := CylinderMesh.new()
		grip_band.radial_segments = 8
		grip_band.top_radius = 0.047
		grip_band.bottom_radius = 0.047
		grip_band.height = 0.027
		_add_part("GripWrap_%d" % index, grip_band, Vector3(0, -0.31 + float(index) * 0.07, 0), GRIP_DARK)
	# Belirgin, yelpaze bicimli metal balta basligi, alttaki kesici kenar
	# siluetini kucuk ekranda da koruyacak sekilde orta buyuklukte.
	_add_part("AxeHead", _blade_mesh(), Vector3.ZERO, METAL)
	var blade_edge := BoxMesh.new()
	blade_edge.size = Vector3(0.035, 0.48, 0.115)
	_add_part("CuttingEdge", blade_edge, Vector3(0.50, 0.28, 0), EDGE)
	var socket := CylinderMesh.new()
	socket.radial_segments = 8
	socket.top_radius = 0.075
	socket.bottom_radius = 0.075
	socket.height = 0.24
	_add_part("HeadSocket", socket, Vector3(0, 0.25, 0), METAL)

func _blade_mesh() -> ArrayMesh:
	# X/Y profilini Z boyunca extrude et; basit kutudan daha net balta silueti.
	var shape := [
		Vector2(-0.055, 0.14), Vector2(0.20, 0.15),
		Vector2(0.43, 0.04), Vector2(0.49, 0.04),
		Vector2(0.48, 0.52), Vector2(0.43, 0.52),
		Vector2(0.20, 0.40), Vector2(-0.055, 0.40),
	]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var front_z := 0.065
	var back_z := -0.065
	for index in range(1, shape.size() - 1):
		_push_triangle(tool, Vector3(shape[0].x, shape[0].y, front_z), Vector3(shape[index].x, shape[index].y, front_z), Vector3(shape[index + 1].x, shape[index + 1].y, front_z))
		_push_triangle(tool, Vector3(shape[0].x, shape[0].y, back_z), Vector3(shape[index + 1].x, shape[index + 1].y, back_z), Vector3(shape[index].x, shape[index].y, back_z))
	for index in range(shape.size()):
		var next_index := (index + 1) % shape.size()
		var a := Vector3(shape[index].x, shape[index].y, front_z)
		var b := Vector3(shape[next_index].x, shape[next_index].y, front_z)
		var c := Vector3(shape[index].x, shape[index].y, back_z)
		var d := Vector3(shape[next_index].x, shape[next_index].y, back_z)
		_push_triangle(tool, a, b, c)
		_push_triangle(tool, b, d, c)
	tool.generate_normals()
	return tool.commit()

func _push_triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	tool.add_vertex(a)
	tool.add_vertex(b)
	tool.add_vertex(c)

func _add_part(part_name: String, geometry: Mesh, local_pos: Vector3, tint: Color) -> void:
	var item := MeshInstance3D.new()
	item.name = part_name
	item.mesh = geometry
	item.position = local_pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.86
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	item.material_override = mat
	add_child(item)
