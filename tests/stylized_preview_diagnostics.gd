extends SceneTree

# Mevcut Meshy ormani bozmadan iki dusuk-poly sanat prototipini kurup dogrular.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var preview_script: Script = load("res://scripts/stylized_asset_preview.gd")
	var showcase: Node = preview_script.new()
	root.add_child(showcase)
	var tree: Node = showcase.get_node_or_null("StylizedOak")
	var rock: Node = showcase.get_node_or_null("StylizedBoulder")
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
	print("AshvaleStyleTest preview=", ok, " tree_triangles=", geometries[0], " rock_triangles=", geometries[1])
	quit(0 if ok else 1)
