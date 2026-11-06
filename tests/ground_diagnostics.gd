extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://main.tscn")
    if packed == null:
        push_error("AshvaleGroundTest: no main scene")
        quit(1)
        return
    var scene := packed.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_physics_process(false)
    var ground := scene.get_node_or_null("Ground") as StaticBody3D
    if ground == null:
        push_error("AshvaleGroundTest: Ground static body missing")
        quit(1)
        return
    var surface := ground.get_node_or_null("TerrainSurface") as MeshInstance3D
    var collider := ground.get_node_or_null("TerrainCollider") as CollisionShape3D
    if surface == null or collider == null or not surface.mesh is PlaneMesh:
        push_error("AshvaleGroundTest: plane or collider missing")
        quit(1)
        return
    var plane: PlaneMesh = surface.mesh
    var shape: BoxShape3D = collider.shape
    var mat := surface.material_override as ShaderMaterial
    if shape == null or mat == null:
        push_error("AshvaleGroundTest: ground material/physics missing")
        quit(1)
        return
    var texture: Texture2D = mat.get_shader_parameter("ground_albedo") as Texture2D
    if texture == null or texture.get_width() < 1024 or texture.get_height() < 1024:
        push_error("AshvaleGroundTest: high res ground texture missing")
        quit(1)
        return
    var tile_size: float = mat.get_shader_parameter("meters_per_tile")
    var total_size: float = scene.GROUND_SIZE
    var coverage_ok: bool = absf(plane.size.x - total_size) < 0.01 and absf(plane.size.y - total_size) < 0.01 and absf(shape.size.x - total_size) < 0.01 and absf(shape.size.z - total_size) < 0.01
    var repeat_ok: bool = absf(tile_size - 4.0) < 0.01
    if not coverage_ok or not repeat_ok or mat.shader == null:
        push_error("AshvaleGroundTest: tiling or collider dimension mismatch")
        quit(1)
        return
    print("AshvaleGroundTest passed: ", plane.size, " texture=", texture.get_width(), "x", texture.get_height(), " tile=", tile_size, "m")
    quit(0)
