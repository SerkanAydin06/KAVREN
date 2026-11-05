extends Node3D

# Ashvale 2026: stylize dogal yuzeyler. Tek parca agac/kaya stili karsilastirmasi.
# Ornekler sinirsiz ve pahali Meshy islemi gerektirmeyen Godot geometri prototipleridir.
# Buradaki rakamlar mevcut Meshy model/texture kaynaklarini degistirmez.

const BARK := Color("#493325")
const BARK_LIGHT := Color("#755039")
const BARK_SHADE := Color("#39291f")
const LEAF_DARK := Color("#526b3f")
const LEAF_MED := Color("#66824a")
const LEAF_LIGHT := Color("#85975d")
const STONE := Color("#777b76")
const STONE_LIGHT := Color("#93978b")
const STONE_DARK := Color("#59645f")
const MOSS := Color("#526b3f")

func _ready() -> void:
	var oak := _create_tree()
	oak.name = "StylizedOak"
	oak.position = Vector3(-4.5, 0, -8.5)
	add_child(oak)
	var rock := _create_rock()
	rock.name = "StylizedBoulder"
	rock.position = Vector3(4.5, 0, -8.5)
	add_child(rock)
	_create_label(oak, "STILIZE MESE", Vector3(0, 7.9, 0))
	_create_label(rock, "STILIZE KAYA", Vector3(0, 2.45, 0))

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.96
	mat.metallic = 0.0
	return mat

func _mesh(parent: Node3D, shape: Mesh, center: Vector3, scale_vector: Vector3, color: Color, item_name: String) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = item_name
	item.mesh = shape
	item.position = center
	item.scale = scale_vector
	item.material_override = _material(color)
	parent.add_child(item)
	return item

func _cylinder(parent: Node3D, from_point: Vector3, to_point: Vector3, bottom: float, top: float, color: Color, item_name: String) -> MeshInstance3D:
	var direction := to_point - from_point
	var cylinder := CylinderMesh.new()
	cylinder.radial_segments = 8
	cylinder.rings = 1
	cylinder.bottom_radius = bottom
	cylinder.top_radius = top
	cylinder.height = direction.length()
	var part := _mesh(parent, cylinder, (from_point + to_point) * 0.5, Vector3.ONE, color, item_name)
	part.quaternion = Quaternion(Vector3.UP, direction.normalized())
	return part

func _create_tree() -> Node3D:
	var tree := Node3D.new()
	tree.name = "StylizedOak"
	_cylinder(tree, Vector3(0, 0, 0), Vector3(0.12, 4.8, 0.05), 0.56, 0.30, BARK, "Trunk")
	_cylinder(tree, Vector3(0, 0.06, 0), Vector3(0, 0.72, 0), 0.73, 0.49, BARK_LIGHT, "RootFlare")
	for index in range(5):
		var angle := TAU * float(index) / 5.0 + 0.22
		var foot := Vector3(cos(angle) * 0.32, 0.09, sin(angle) * 0.32)
		var tip := Vector3(cos(angle) * 1.02, 0.21, sin(angle) * 1.02)
		_cylinder(tree, foot, tip, 0.19, 0.05, BARK, "Root_%d" % index)
	var branches: Array[Vector3] = [
		Vector3(-1.66, 4.74, -0.4), Vector3(1.56, 4.96, 0.39),
		Vector3(-0.42, 5.00, 1.58), Vector3(0.49, 5.22, -1.55),
	]
	for index in range(branches.size()):
		_cylinder(tree, Vector3(0.09, 3.62 + float(index % 2) * 0.31, 0), branches[index], 0.23, 0.09, BARK_LIGHT, "Branch_%d" % index)
	# 8 buyuk dusuk-poly hacim: kucuk binlerce yaprak yerine okunakli siluet.
	var foliage_locations: Array[Vector3] = [
		Vector3(-1.60, 5.38, -0.34), Vector3(1.60, 5.48, 0.39),
		Vector3(-0.28, 5.54, 1.46), Vector3(0.46, 5.64, -1.46),
		Vector3(-0.66, 6.24, 0.22), Vector3(0.62, 6.30, 0.18),
		Vector3(0.07, 6.98, -0.30), Vector3(0.02, 5.60, 0.14),
	]
	var leaf_colors: Array[Color] = [LEAF_MED, LEAF_DARK, LEAF_LIGHT, LEAF_MED, LEAF_LIGHT, LEAF_MED, LEAF_LIGHT, LEAF_DARK]
	for index in range(foliage_locations.size()):
		var leaves := SphereMesh.new()
		leaves.radial_segments = 9
		leaves.rings = 5
		leaves.radius = 1.06
		leaves.height = 2.12
		var cluster := _mesh(tree, leaves, foliage_locations[index], Vector3(1.15, 0.78, 1.07), leaf_colors[index], "Foliage_%d" % index)
		cluster.rotation.y = float(index) * 0.52
	_add_collision(tree, 0.55, 4.2, Vector3(0, 2.1, 0))
	return tree

func _add_collision(parent: Node3D, radius: float, height: float, center: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "CollisionBody"
	parent.add_child(body)
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = height
	shape.shape = cylinder
	shape.position = center
	body.add_child(shape)

func _rock_mesh(radius: float, height: float, color_factor: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segment_count := 9
	var previous: Array[Vector3] = []
	var middle: Array[Vector3] = []
	var upper: Array[Vector3] = []
	for index in range(segment_count):
		var angle := TAU * float(index) / float(segment_count)
		var wobble := 1.0 + 0.13 * sin(angle * 3.0 + color_factor)
		previous.append(Vector3(cos(angle) * radius * 0.72 * wobble, 0.04, sin(angle) * radius * 0.72 * wobble))
		middle.append(Vector3(cos(angle) * radius * wobble, height * (0.53 + 0.05 * cos(angle * 4.0)), sin(angle) * radius * wobble))
		upper.append(Vector3(cos(angle) * radius * 0.59 * wobble, height * (0.90 + 0.04 * sin(angle * 2.0)), sin(angle) * radius * 0.59 * wobble))
	var colors: Array[Color] = [STONE, STONE_LIGHT, STONE_DARK, STONE, STONE_LIGHT, STONE_DARK, STONE]
	for index in range(segment_count):
		var next := (index + 1) % segment_count
		var base_color: Color = colors[index % colors.size()]
		_triangle(tool, previous[index], middle[index], previous[next], base_color)
		_triangle(tool, previous[next], middle[index], middle[next], base_color)
		var top_color: Color = colors[(index + 2) % colors.size()]
		_triangle(tool, middle[index], upper[index], middle[next], top_color)
		_triangle(tool, middle[next], upper[index], upper[next], top_color)
		_triangle(tool, upper[index], Vector3(0, height, 0), upper[next], STONE_LIGHT)
	tool.generate_normals()
	var rock := tool.commit()
	return rock

func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, tint: Color) -> void:
	tool.set_color(tint)
	tool.add_vertex(a)
	tool.add_vertex(b)
	tool.add_vertex(c)

func _create_rock() -> Node3D:
	var rock := Node3D.new()
	rock.name = "StylizedBoulder"
	var stone_material := StandardMaterial3D.new()
	stone_material.vertex_color_use_as_albedo = true
	stone_material.roughness = 0.99
	var main_stone := MeshInstance3D.new()
	main_stone.name = "FacetedRock"
	main_stone.mesh = _rock_mesh(1.54, 1.55, 0.75)
	main_stone.material_override = stone_material
	rock.add_child(main_stone)
	for index in range(2):
		var chip := MeshInstance3D.new()
		chip.name = "SmallerRock_%d" % index
		chip.mesh = _rock_mesh(0.46, 0.56, float(index))
		chip.position = Vector3(-1.65 if index == 0 else 1.59, 0, 0.48 if index == 0 else -0.28)
		chip.rotation.y = 0.5 * float(index)
		chip.material_override = stone_material
		rock.add_child(chip)
	# Birkac duz yosun lekesi; fotogercekci kaplama gürültüsü yok.
	var moss_mesh := SphereMesh.new()
	moss_mesh.radial_segments = 8
	moss_mesh.rings = 4
	moss_mesh.radius = 0.64
	moss_mesh.height = 1.28
	_mesh(rock, moss_mesh, Vector3(0.36, 1.47, 0.14), Vector3(0.8, 0.13, 0.52), MOSS, "Moss")
	_add_collision(rock, 1.19, 1.48, Vector3(0, 0.74, 0))
	return rock

func _create_label(target: Node3D, caption: String, local_pos: Vector3) -> void:
	var tag := Label3D.new()
	tag.name = "StyleLabel"
	tag.text = caption
	tag.position = local_pos
	tag.font_size = 48
	tag.pixel_size = 0.004
	tag.outline_size = 7
	tag.modulate = Color("#e4d8b5")
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	target.add_child(tag)
