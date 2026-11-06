extends SceneTree

# FBX geometri, materyal, tur cesitliligi, capraz sahne paylasimi ve carpisma kontrolu.
func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var total_failures := 0
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
		if node.has_node("Model/Foliage_0") and node.has_node("Model/Trunk"):
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
	print("AshvaleTreeTest forest: trees=", trees, " models=", real_models, " collisions=", collision_shapes, " species=", seen_species.size())
	if trees != game.TREE_COUNT or real_models != trees or collision_shapes != trees or seen_species.size() != 4:
		total_failures += 1
	print("AshvaleTreeTest failures=", total_failures)
	quit(1 if total_failures > 0 else 0)
