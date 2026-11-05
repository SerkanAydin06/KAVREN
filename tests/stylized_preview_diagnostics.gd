extends SceneTree

# Mevcut Meshy ormani bozmadan iki dusuk-poly sanat prototipini kurup dogrular.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var game: Node3D = scene.instantiate()
	root.add_child(game)
	await process_frame
	var showcase: Node = game.get_node_or_null("ArtDirectionShowcase")
	var tree: Node = game.get_node_or_null("ArtDirectionShowcase/StylizedOak")
	var rock: Node = game.get_node_or_null("ArtDirectionShowcase/StylizedBoulder")
	var ok := showcase != null and tree != null and rock != null
	var geometries: Array[int] = []
	for item in [tree, rock]:
		var mesh_count := 0
		var total_triangles := 0
		var children: Array[Node] = []
		if item != null:
			children.append(item)
			if item.get_node_or_null("CollisionBody/CollisionShape3D") == null:
				ok = false
		while not children.is_empty():
			var current: Node = children.pop_back()
			if current is MeshInstance3D:
				var mesh_node: MeshInstance3D = current as MeshInstance3D
				if mesh_node.mesh != null:
					mesh_count += 1
					for index in range(mesh_node.mesh.get_surface_count()):
						var vertex_count: int = mesh_node.mesh.surface_get_array_len(index)
						total_triangles += int(vertex_count / 3)
			for child in current.get_children():
				children.append(child)
		geometries.append(total_triangles)
		if mesh_count == 0 or total_triangles <= 0 or total_triangles > 8000:
			ok = false
	var original_forest := 0
	for child in game.get_children():
		if child.has_meta("tree_species") and String(child.get_meta("resource_type", "")) == "wood":
			original_forest += 1
	if original_forest != game.TREE_COUNT:
		ok = false
	print("AshvaleStyleTest preview=", ok, " tree_triangles=", geometries[0], " rock_triangles=", geometries[1], " existing_Meshy_trees=", original_forest)
	quit(0 if ok else 1)
