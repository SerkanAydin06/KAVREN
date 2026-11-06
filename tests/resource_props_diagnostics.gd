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
	print("AshvalePropsTest mineables=", by_kind, " ferns=", ferns, " stumps=", stumps, " copper=", game.copper, " failures=", failures)
	quit(1 if failures > 0 else 0)
