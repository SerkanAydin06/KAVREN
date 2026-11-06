extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var game: Node = load("res://creature_valley.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	var failures := 0
	await physics_frame
	if not game.height_at(0,-21)>2 or game.creatures.size()!=3:
		failures += 1
	game.player.position = game.creatures[0].position
	game._interact()
	game._interact()
	if game.roster != [0] or game.berries!=1:
		failures += 1
	game.player.position = game.creatures[1].position
	game._interact()
	for turn in range(6):
		game._battle_action(false)
	if game.battle!=-1 or game.levels[0]!=2 or not game.creatures[1].tired:
		failures += 1
	game._interact()
	if not game.roster.has(1):
		failures += 1
	game.player.position = Vector3(0,game.height_at(0,-33),-30)
	if not game._open_path():
		failures += 1
	game._checkpoint_creatures()
	var restored: Node = load("res://creature_valley.tscn").instantiate()
	root.add_child(restored)
	restored.set_physics_process(false)
	if not restored.gate_open or restored.roster != game.roster or restored.levels[0]!=2:
		failures += 1
	await physics_frame
	var ray := PhysicsRayQueryParameters3D.create(Vector3(0,8,-21),Vector3(0,-5,-21))
	var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty() or absf(hit.position.y-game.height_at(0,-21))>0.08:
		failures += 1
	DirAccess.remove_absolute(game.STATE_PATH)
	print("AshvaleCompanionsTest failures=",failures)
	quit(0 if failures==0 else 1)
