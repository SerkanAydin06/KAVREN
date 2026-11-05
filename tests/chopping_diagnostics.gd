extends SceneTree

# End-to-end axe hit, damage, falling, cut stump, wood drops, E pickup.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	var original: Node3D = null
	for node in game.get_children():
		if node is Node3D and String(node.get_meta("tree_species", "")) == "Oak":
			original = node as Node3D
			break
	if original == null:
		push_error("AshvaleChopTest missing oak")
		quit(1)
		return
	original.position = Vector3(0, 0, -2.0)
	game.player.position = Vector3.ZERO
	game.yaw = 0.0
	var failures := 0
	var timber_count := 0
	for hit in range(3):
		game.attack_remaining = 0.0
		game._start_attack()
		if game.pending_chop_target != original or not is_equal_approx(game.pending_chop_timer, game.CHOP_IMPACT_DELAY):
			print("AshvaleChopTest FAILURE_1 details: hits=", original.hits_taken, " pending=", game.pending_chop_target, " falling=", original.is_falling, " drops_resources=", game.resource_nodes.size(), " wood=", game.wood)
			failures += 1
		game._advance_axe_impact(0.12)
		if original.hits_taken != hit:
			print("AshvaleChopTest FAILURE_2 details: hits=", original.hits_taken, " pending=", game.pending_chop_target, " falling=", original.is_falling, " drops_resources=", game.resource_nodes.size(), " wood=", game.wood)
			failures += 1
		game._advance_axe_impact(0.13)
		if original.hits_taken != hit + 1:
			print("AshvaleChopTest FAILURE_3 details: hits=", original.hits_taken, " pending=", game.pending_chop_target, " falling=", original.is_falling, " drops_resources=", game.resource_nodes.size(), " wood=", game.wood)
			failures += 1
		if hit < 2 and original.is_falling:
			print("AshvaleChopTest FAILURE_4 details: hits=", original.hits_taken, " pending=", game.pending_chop_target, " falling=", original.is_falling, " drops_resources=", game.resource_nodes.size(), " wood=", game.wood)
			failures += 1
	if not original.is_falling or original.get_meta("resource_type") != "spent_tree":
		print("AshvaleChopTest FAILURE_5 details: hits=", original.hits_taken, " pending=", game.pending_chop_target, " falling=", original.is_falling, " drops_resources=", game.resource_nodes.size(), " wood=", game.wood)
		failures += 1
	if game.resource_nodes.has(original):
		print("AshvaleChopTest FAILURE_6 details: hits=", original.hits_taken, " pending=", game.pending_chop_target, " falling=", original.is_falling, " drops_resources=", game.resource_nodes.size(), " wood=", game.wood)
		failures += 1
	await create_timer(1.15).timeout
	var stump := game.get_node_or_null("Oak_00_Stump")
	if stump == null or stump.get_node_or_null("StumpBody/CollisionShape3D") == null:
		print("AshvaleChopTest FAILURE_7 details: hits=", original.hits_taken, " pending=", game.pending_chop_target, " falling=", original.is_falling, " drops_resources=", game.resource_nodes.size(), " wood=", game.wood)
		failures += 1
	var drops: Array[Node3D] = []
	for node in game.resource_nodes:
		if is_instance_valid(node) and String(node.get_meta("resource_type", "")) == "wood_drop":
			drops.append(node)
	if drops.size() != 3:
		print("AshvaleChopTest FAILURE_8 details: hits=", original.hits_taken, " pending=", game.pending_chop_target, " falling=", original.is_falling, " drops_resources=", game.resource_nodes.size(), " wood=", game.wood)
		failures += 1
	else:
		var target := drops[0]
		game.player.global_position = target.global_position + Vector3(0.2, 0, 0.2)
		timber_count = game.wood
		game._collect_resource()
		if game.wood != timber_count + 1 or game.resource_nodes.has(target):
			print("AshvaleChopTest FAILURE_9 details: hits=", original.hits_taken, " pending=", game.pending_chop_target, " falling=", original.is_falling, " drops_resources=", game.resource_nodes.size(), " wood=", game.wood)
			failures += 1
	# Preview oak is also choppable and registered, not a purely decorative prop.
	var preview_oak := game.get_node_or_null("ArtDirectionShowcase/StylizedOak")
	if preview_oak == null or not game.resource_nodes.has(preview_oak) or not preview_oak.has_method("take_axe_hit"):
		print("AshvaleChopTest FAILURE_10 details: hits=", original.hits_taken, " pending=", game.pending_chop_target, " falling=", original.is_falling, " drops_resources=", game.resource_nodes.size(), " wood=", game.wood)
		failures += 1
	print("AshvaleChopTest hits=3 fall=true drops=", drops.size(), " stump=", stump != null, " preview_tree=", preview_oak != null, " failures=", failures)
	quit(1 if failures > 0 else 0)
