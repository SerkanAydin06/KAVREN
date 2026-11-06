extends SceneTree

# FBX geometri, materyal, tur cesitliligi, capraz sahne paylasimi ve carpisma kontrolu.
func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var total_failures := 0
	var species_triangles: Array[int] = []
	for species_index in range(4):
		var fbx_path: String = String(load("res://scripts/main.gd").TREE_MODEL_PATHS[species_index])
		var texture_path: String = String(load("res://scripts/main.gd").TREE_TEXTURE_PATHS[species_index])
		var imported_resource: Resource = load(fbx_path)
		var diffuse: Resource = load(texture_path)
		if not imported_resource is PackedScene or not diffuse is Texture2D:
			push_error("AshvaleTreeTest failed import: " + fbx_path)
			total_failures += 1
			continue
		var imported_scene := (imported_resource as PackedScene).instantiate()
		root.add_child(imported_scene)
		var pending: Array[Node] = [imported_scene]
		var mesh_count := 0
		var triangle_count := 0
		var textured_surfaces := 0
		while not pending.is_empty():
			var node: Node = pending.pop_back()
			if node is MeshInstance3D:
				var mesh_node := node as MeshInstance3D
				if mesh_node.mesh != null:
					mesh_count += 1
					for surface_index in range(mesh_node.mesh.get_surface_count()):
						var surface_indices: int = mesh_node.mesh.surface_get_array_index_len(surface_index)
						var surface_vertices: int = mesh_node.mesh.surface_get_array_len(surface_index)
						triangle_count += (surface_indices if surface_indices > 0 else surface_vertices) / 3
						var mat := mesh_node.get_active_material(surface_index)
						if mat is BaseMaterial3D and (mat as BaseMaterial3D).albedo_texture != null:
							textured_surfaces += 1
			for child in node.get_children():
				pending.append(child)
		print("AshvaleTreeTest imported: ", fbx_path, " meshes=", mesh_count, " triangles=", triangle_count, " texture_surfaces=", textured_surfaces)
		species_triangles.append(triangle_count)
		if mesh_count == 0 or triangle_count == 0:
			total_failures += 1
		imported_scene.queue_free()
	var packed: PackedScene = load("res://main.tscn")
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	var trees := 0
	var real_models := 0
	var collision_shapes := 0
	var seen_species: Dictionary = {}
	for node in game.get_children():
		if not node is Node3D or String(node.get_meta("resource_type", "")) != "wood":
			continue
		trees += 1
		seen_species[String(node.get_meta("tree_species", ""))] = true
		if node.has_node("Model"):
			real_models += 1
		# Kokler topraga gomulu: model tabani zeminin altinda olmali.
		var model_node: Node3D = node.get_node_or_null("Model")
		var model_bottom := 1.0
		if model_node != null:
			model_bottom = model_node.position.y + game._measure_model_bounds(model_node).position.y * model_node.scale.y
		if model_node != null and model_bottom >= -0.1:
			total_failures += 1
		var collision: Node = node.get_node_or_null("TrunkBody/CollisionShape3D")
		if collision is CollisionShape3D:
			var collision_shape := collision as CollisionShape3D
			if collision_shape.shape is CylinderShape3D and collision_shape.position.y > 0.0:
				collision_shapes += 1
	print("AshvaleTreeTest forest: trees=", trees, " models=", real_models, " collisions=", collision_shapes, " species=", seen_species.size(), " triangles=", species_triangles)
	if trees != game.TREE_COUNT or real_models != trees or collision_shapes != trees or seen_species.size() != 4:
		total_failures += 1
	print("AshvaleTreeTest failures=", total_failures)
	quit(1 if total_failures > 0 else 0)
