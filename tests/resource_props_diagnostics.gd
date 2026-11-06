extends SceneTree

# Yeni Meshy objeleri: hepsi import ediliyor mu, PBR dokulari bagli mi,
# kazma ile kaya/cevher kiriliyor mu ve parcalar E ile toplanabiliyor mu.
const MODEL_LIBRARY := preload("res://scripts/model_library.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures := 0
	for key in MODEL_LIBRARY.MODELS.keys():
		var model: Node3D = MODEL_LIBRARY.instantiate(String(key), 1.0)
		var mat: StandardMaterial3D = MODEL_LIBRARY.material(String(key))
		if model == null or mat == null or mat.albedo_texture == null:
			print("AshvalePropsTest missing model or albedo: ", key)
			failures += 1
			continue
		var bounds: AABB = MODEL_LIBRARY.measure_bounds(model)
		var height: float = bounds.size.y * model.scale.y
		if absf(height - 1.0) > 0.02 or absf(bounds.position.y * model.scale.y + model.position.y) > 0.02:
			print("AshvalePropsTest bad normalization: ", key, " height=", height)
			failures += 1
		print("AshvalePropsTest model=", key, " triangles=", MODEL_LIBRARY.triangle_count(model), " normal=", mat.normal_texture != null)
		model.free()
	var scene: PackedScene = load("res://main.tscn")
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	var by_kind := {"stone": 0, "copper": 0, "iron": 0}
	var copper_rock: Node3D = null
	for node in game.resource_nodes:
		if String(node.get_meta("resource_type", "")) == "mineable":
			by_kind[node.resource_kind] += 1
			if node.resource_kind == "copper" and copper_rock == null:
				copper_rock = node
			if node.get_node_or_null("Model") == null or node.get_node_or_null("RockBody/CollisionShape3D") == null:
				failures += 1
	if by_kind["stone"] < 6 or by_kind["copper"] < 2 or by_kind["iron"] < 2 or copper_rock == null:
		print("AshvalePropsTest missing mineables: ", by_kind)
		quit(1)
		return
	var ferns := 0
	var stumps := 0
	for node in game.get_children():
		if String(node.name).begins_with("Fern_"):
			ferns += 1
		elif String(node.name).begins_with("OldStump_"):
			stumps += 1
	if ferns != game.FERN_COUNT or stumps != game.DECOR_STUMP_COUNT:
		failures += 1
	# Balta ile kaya kazilmaz; kazmaya gecince kazilir.
	copper_rock.position = Vector3(0, 0, -(game._target_radius(copper_rock) + 0.6))
	game.player.position = Vector3.ZERO
	game.yaw = 0.0
	game._select_tool("axe")
	game._start_attack()
	if game.pending_chop_target == copper_rock:
		failures += 1
	game.attack_remaining = 0.0
	game.pending_chop_target = null
	game._select_tool("pickaxe")
	if not game.equipped_pickaxe.visible or game.equipped_axe.visible:
		failures += 1
	for hit in range(copper_rock.max_hits):
		game.attack_remaining = 0.0
		game._start_attack()
		if game.pending_chop_target != copper_rock:
			failures += 1
		game._advance_axe_impact(game.CHOP_IMPACT_DELAY + 0.01)
		if copper_rock.hits_taken != hit + 1:
			failures += 1
	if not copper_rock.is_depleted or game.resource_nodes.has(copper_rock):
		failures += 1
	var chunks: Array[Node3D] = []
	for node in game.resource_nodes:
		if is_instance_valid(node) and String(node.get_meta("resource_type", "")) == "copper_drop":
			chunks.append(node)
	if chunks.size() != copper_rock.drop_count:
		failures += 1
	var before: int = game.copper
	for chunk in chunks:
		game.player.global_position = chunk.global_position + Vector3(0.2, 0, 0.2)
		game._collect_resource()
	if game.copper != before + chunks.size():
		failures += 1
	failures += await _test_expedition(game)
	print("AshvalePropsTest mineables=", by_kind, " ferns=", ferns, " stumps=", stumps, " copper=", game.copper, " failures=", failures)
	quit(1 if failures > 0 else 0)

func _check(condition: bool, label: String) -> int:
	if not condition:
		print("Expedition regression: ", label)
	return 0 if condition else 1

func _test_expedition(game: Node) -> int:
	var failures := 0
	var entrance: Vector3 = game.MINE.ENTRANCE
	await physics_frame
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	var center := entrance + Vector3(0, 1.5, -12)
	var passage := PhysicsRayQueryParameters3D.create(entrance + Vector3(0, 1.5, 4), center, 4)
	failures += _check(space.intersect_ray(passage).is_empty(), "gallery entrance traversable")
	var wall := PhysicsRayQueryParameters3D.create(center, center + Vector3.RIGHT * 6, 4)
	failures += _check(not space.intersect_ray(wall).is_empty(), "gallery wall blocks passage")
	game.camera_pivot.position = center
	game.camera_pivot.rotation = Vector3(0, PI/2, 0)
	game._update_gallery_camera()
	failures += _check(game.camera_pivot.get_node("Camera").position.length() < 4, "camera stays inside gallery wall")
	game.player.position = entrance
	game._update_expedition()
	failures += _check(game.expedition_stage == game.Expedition.FIND, "first night gate")
	game.survived_first_night = true
	game._update_expedition()
	failures += _check(game.expedition_stage == game.Expedition.RETURN, "mine discovered")
	game.inventory.set_count("copper", 0)
	game._select_tool("pickaxe")
	for index in range(3):
		var seam: Node3D = game.get_node("MineCopper%d" % index)
		game.player.position = seam.position + Vector3.BACK * (game._target_radius(seam) + 0.5)
		game.yaw = 0
		for hit in range(4):
			game.attack_remaining = 0
			game._start_attack()
			game._advance_axe_impact(game.CHOP_IMPACT_DELAY + 0.01)
		for chunk in game.resource_nodes.duplicate():
			if chunk.get_meta("harvest_source", "") == str(seam.name):
				game.player.position = chunk.position
				game._collect_resource()
	failures += _check(game.copper == 6, "entrance yields crafting materials")
	var iron: Node3D = game.get_node(game.MINE.IRON_SOURCE)
	game.player.position = iron.position + Vector3.BACK * (game._target_radius(iron) + 0.5)
	game.attack_remaining = 0
	game._start_attack()
	game._advance_axe_impact(game.CHOP_IMPACT_DELAY + 0.01)
	failures += _check(iron.hits_taken == 0, "stone pickaxe cannot mine gallery iron")
	game.player.position = game.CAMP_POSITION
	game._update_expedition()
	failures += _check(game.expedition_stage == game.Expedition.MINE_IRON, "return with copper")
	game.inventory.add("wood", 3)
	game.inventory.add("rope", 1)
	failures += _check(game.inventory.craft(game.ITEMS.recipe_for("copper_pickaxe")), "craft copper pickaxe")
	for i in range(game.inventory.HOTBAR_SIZE):
		if game.inventory.item_at(i) == "copper_pickaxe":
			game.attack_remaining = 0
			game._select_slot(i)
	game.player.position = iron.position + Vector3.BACK * (game._target_radius(iron) + 0.5)
	for hit in range(4):
		game.attack_remaining = 0
		game._start_attack()
		game._advance_axe_impact(game.CHOP_IMPACT_DELAY + 0.01)
	var path := "user://mine-test-only.save"
	game.SAVE.write_state(game.SAVE.capture(game), path)
	var saved: Dictionary = game.SAVE.read_state(path)
	var resumed: Node = load("res://main.tscn").instantiate()
	root.add_child(resumed)
	resumed.set_physics_process(false)
	if saved.is_empty():
		failures += _check(false, "read expedition save")
	else:
		game.SAVE.restore(resumed, saved)
		failures += _check(resumed.expedition_stage == game.Expedition.MINE_IRON and not resumed.mine_iron_collected, "resume before collecting iron")
		for chunk in resumed.resource_nodes.duplicate():
			if chunk.get_meta("harvest_source", "") == game.MINE.IRON_SOURCE:
				resumed.player.position = chunk.position
				resumed._collect_resource()
				break
		resumed._update_expedition()
		failures += _check(resumed.expedition_stage == game.Expedition.COMPLETE and resumed.iron > 0, "collect restored mine iron to finish")
	DirAccess.remove_absolute(path)
	resumed.queue_free()
	await process_frame
	return failures
