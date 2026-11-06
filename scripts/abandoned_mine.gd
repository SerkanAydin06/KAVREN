extends StaticBody3D

const ENTRANCE := Vector3(0, 0, -74)
const IRON_SOURCE := "MineIron"
const WOOD := Color("#67513c")
const TAR := Color("#42372f")
const ROCK := Color("#383a42")
const IRON := Color("#61534b")
var materials := {}

func _ready() -> void:
	collision_layer = 5
	# A covered gallery opens toward camp. Keep a clear walking lane down its centre.
	_box(Vector3(-4, 2.8, -10), Vector3(1, 5.6, 21), ROCK)
	_box(Vector3(4, 2.8, -10), Vector3(1, 5.6, 21), ROCK)
	_box(Vector3(0, 5.5, -10), Vector3(9, 1, 21), ROCK)
	_box(Vector3(0, 2.8, -20), Vector3(8, 5.6, 1), ROCK)
	# Exposed rock shoulders bury the gallery walls; everything stays outside the passage.
	var strata := [Color("#55565a"), Color("#4c5054"), Color("#585952")]
	for side in [-1, 1]:
		for index in range(6):
			var outcrop := MeshInstance3D.new()
			var stone := SphereMesh.new()
			stone.radial_segments = 7
			stone.rings = 3
			outcrop.mesh = stone
			outcrop.position = Vector3(side * 6.1, 1.3, -2.3 - index * 3.2)
			outcrop.scale = Vector3(5.3, 4.8 + index % 3, 6.2)
			outcrop.rotation.y = index * 1.1
			outcrop.material_override = _material(strata[index % strata.size()])
			add_child(outcrop)
			var shell := CollisionShape3D.new()
			var hull := ConvexPolygonShape3D.new()
			var points := PackedVector3Array()
			for vertex in stone.get_mesh_arrays()[Mesh.ARRAY_VERTEX]:
				points.append(outcrop.transform * vertex)
			hull.points = points
			shell.shape = hull
			add_child(shell)
	for z in [0, -5, -10, -15, -19]:
		for x in [-3, 3]:
			_box(Vector3(x, 2.4, z), Vector3(0.34, 4.8, 0.48), WOOD)
		_box(Vector3(0, 4.65, z), Vector3(6.4, 0.45, 0.48), WOOD)
	for x in [-0.8, 0.8]:
		_box(Vector3(x, 0.09, -7), Vector3(0.1, 0.1, 24), IRON, false)
	for z in range(-18, 6, 2):
		_box(Vector3(0, 0.04, z), Vector3(2.4, 0.08, 0.28), TAR, false)
	# Hoist headframe, diagonal braces and winding wheel silhouette above the trees.
	for x in [-2.6, 2.6]:
		for z in [1.3, -2.3]:
			_box(Vector3(x, 8, z), Vector3(0.52, 16, 0.52), WOOD)
	for y in [6, 10, 14]:
		_box(Vector3(0, y, 1.3), Vector3(5.8, 0.36, 0.36), TAR, false)
		_box(Vector3(0, y+1.8, 1.3), Vector3(6.4, 0.26, 0.3), WOOD, false).rotation.z = 0.61
	_box(Vector3(0, 16, -0.5), Vector3(6.3, 0.42, 4.4), WOOD)
	var wheel := MeshInstance3D.new()
	var rim := TorusMesh.new()
	rim.inner_radius = 1.15
	rim.outer_radius = 1.65
	wheel.mesh = rim
	wheel.position = Vector3(0, 17.2, -0.5)
	wheel.rotation.x = PI * 0.5
	wheel.material_override = _material(IRON)
	add_child(wheel)

func _box(center: Vector3, dimensions: Vector3, tint: Color, solid := true) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = dimensions
	piece.mesh = box
	piece.position = center
	piece.material_override = _material(tint)
	add_child(piece)
	if solid:
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = dimensions
		collider.shape = shape
		collider.position = center
		add_child(collider)
	return piece

func _material(color: Color) -> StandardMaterial3D:
	if not materials.has(color):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.92
		materials[color] = mat
	return materials[color]
