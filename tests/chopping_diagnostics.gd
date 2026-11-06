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
	# Uzaktan vurulamaz: govde yuzeyine 2.5 m.
	var trunk_radius: float = game._target_radius(original)
	original.position = Vector3(0, 0, -(trunk_radius + 2.5))
	game.player.position = Vector3.ZERO
	game.yaw = 0.0
	game.attack_remaining = 0.0
	game._start_attack()
	var far_ok: bool = game.pending_chop_target == null
	game.attack_remaining = 0.0
	# Arkadaki agaca da vurulmaz.
	original.position = Vector3(0, 0, trunk_radius + 0.6)
	game._start_attack()
	var behind_ok: bool = game.pending_chop_target == null
	game.attack_remaining = 0.0
	original.position = Vector3(0, 0, -(trunk_radius + 0.6))
	game.player.position = Vector3.ZERO
	game.yaw = 0.0
	var failures := 0 if far_ok and behind_ok else 1
	if not far_ok or not behind_ok:
		print("AshvaleChopTest reach check failed far=", far_ok, " behind=", behind_ok)
	var timber_count := 0
	for hit in range(3):
		game.attack_remaining = 0.0
		game._start_attack()
		if game.pending_chop_target != original or not is_equal_approx(game.pending_chop_timer, game.CHOP_IMPACT_DELAY):
			failures += 1
		game._advance_axe_impact(0.12)
		if original.hits_taken != hit:
			failures += 1
		game._advance_axe_impact(0.13)
		if original.hits_taken != hit + 1:
			failures += 1
		if hit < 2 and original.is_falling:
			failures += 1
	# Tek bir centik her darbede derinlesir; gövde yuzeyinde ve bel hizasinda.
	var notch: Node3D = original.get_node_or_null("ChopNotch")
	var notch_ready := notch is MeshInstance3D and (notch as MeshInstance3D).mesh != null
	if not notch_ready or original.find_children("CutMark*", "", true, false).size() > 0:
		failures += 1
	else:
		var notch_local: Vector3 = original.to_local(original._notch_surface)
		var radial := Vector2(notch_local.x, notch_local.z).length()
		if absf(notch_local.y - original.CHOP_HEIGHT) > 0.05 or radial < 0.1 or radial > 1.7 or notch.notch_depth <= 0.0:
			failures += 1
		print("AshvaleChopTest notch height=", snappedf(notch_local.y, 0.01), " radius=", snappedf(radial, 0.01), " depth=", snappedf(notch.notch_depth, 0.01))
	if not original.is_falling or original.get_meta("resource_type") != "spent_tree":
		failures += 1
	if game.resource_nodes.has(original):
		failures += 1
	await create_timer(1.15).timeout
	var stump := game.get_node_or_null("Oak_00_Stump")
	print("AshvaleChopTest stump_found=", stump != null, " collider_found=", stump != null and stump.get_node_or_null("StumpBody/CollisionShape3D") != null)
	if stump == null or stump.get_node_or_null("StumpBody/CollisionShape3D") == null:
		failures += 1
	var drops: Array[Node3D] = []
	for node in game.resource_nodes:
		if is_instance_valid(node) and String(node.get_meta("resource_type", "")) == "wood_drop":
			drops.append(node)
	if drops.size() != 3:
		failures += 1
	else:
		var target := drops[0]
		game.player.global_position = target.global_position + Vector3(0.2, 0, 0.2)
		timber_count = game.wood
		game._collect_resource()
		if game.wood != timber_count + 1 or game.resource_nodes.has(target):
			failures += 1
	# Preview oak is also choppable and registered, not a purely decorative prop.
	var preview_oak := game.get_node_or_null("ArtDirectionShowcase/StylizedOak")
	if preview_oak == null or not game.resource_nodes.has(preview_oak) or not preview_oak.has_method("take_axe_hit"):
		failures += 1
	print("AshvaleChopTest hits=3 fall=true drops=", drops.size(), " stump=", stump != null, " preview_tree=", preview_oak != null, " failures=", failures)
	quit(1 if failures > 0 else 0)
