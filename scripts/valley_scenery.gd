extends Node3D

# Decorative scenery uses vertex colors, with one draw batch for the flowers.
func _ready() -> void:
	_make_ridgeline(465.0, 77.0, Color("#72a6a8"))
	_make_ridgeline(510.0, 105.0, Color("#899fb9"))
	_make_wildflowers()

func _color_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.roughness = 1.0
	return material

func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, tint: Color) -> void:
	surface.set_color(tint)
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)

func _crest(angle: float, radius: float, height: float) -> Vector3:
	var skyline := 0.70 + 0.20 * sin(angle * 5 + radius) + 0.14 * cos(angle * 9)
	return Vector3(cos(angle) * radius, height * skyline, sin(angle) * radius)

func _make_ridgeline(radius: float, height: float, tint: Color) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(80):
		var a := _crest(TAU * i / 80.0, radius, height)
		var b := _crest(TAU * (i + 1) / 80.0, radius, height)
		var foot_a := Vector3(a.x, -3, a.z) * 0.92
		var foot_b := Vector3(b.x, -3, b.z) * 0.92
		_triangle(surface, foot_a, b, a, tint)
		_triangle(surface, foot_a, foot_b, b, tint.darkened(0.045))
	surface.generate_normals()
	var ridge := MeshInstance3D.new()
	ridge.mesh = surface.commit()
	var distant_color := _color_material()
	distant_color.disable_fog = true
	ridge.material_override = distant_color
	ridge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ridge)

func _make_wildflowers() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_triangle(surface, Vector3(-0.025, 0, 0), Vector3(0, 0.34, 0), Vector3(0.025, 0, 0), Color("#538451"))
	_triangle(surface, Vector3(0, 0.12, 0), Vector3(-0.17, 0.23, 0.05), Vector3(-0.04, 0.12, 0.09), Color("#7daa55"))
	for i in range(5):
		var angle := TAU * i / 5
		var tip := Vector3(cos(angle), 0, sin(angle)) * 0.15
		var side := Vector3(-sin(angle), 0, cos(angle)) * 0.078
		var heart := Vector3(0, 0.30, 0)
		_triangle(surface, heart, heart + tip + side + Vector3.UP * 0.07, heart + tip - side + Vector3.UP * 0.08, Color("#ffdc88"))
	surface.generate_normals()
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = surface.commit()
	batch.instance_count = 160
	var random := RandomNumberGenerator.new()
	random.seed = 7432
	for group in range(20):
		var side := -1.0 if group % 2 == 0 else 1.0
		var z := random.randf_range(-69, -6)
		var trail_x := lerpf(3.0, 0.0, (2.0 - z) / 76.0) + sin((2.0 - z) / 76.0 * TAU) * 3.0
		var patch := Vector3(trail_x + side * random.randf_range(3.8, 8.5), 0, z)
		for i in range(8):
			var pos := patch + Vector3(random.randf_range(-1, 1), 0, random.randf_range(-1, 1))
			var basis := Basis(Vector3.UP, random.randf_range(0, TAU)).scaled(Vector3.ONE * random.randf_range(0.65, 1.35))
			batch.set_instance_transform(group * 8 + i, Transform3D(basis, pos))
	var flowers := MultiMeshInstance3D.new()
	flowers.multimesh = batch
	flowers.material_override = _color_material()
	flowers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(flowers)
