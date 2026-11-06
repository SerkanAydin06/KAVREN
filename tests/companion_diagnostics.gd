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
	for pool: Vector4 in game.MEADOW.POOLS:
		if game.height_at(pool.x,pool.y) >= game.MEADOW.relief(pool.x,pool.y)-0.035:
			failures += 1
	for creature in game.creatures:
		if creature.visible:
			failures += 1
	for i in range(3):
		var rules = game.COMPANION
		if rules.damage(i,1,(i+1)%3,false) <= rules.damage(i,1,i,false) or rules.damage(i,1,(i+2)%3,false) >= rules.damage(i,1,i,false):
			failures += 1
		if rules.max_hp(i,2)<=rules.max_hp(i,1) or rules.damage(i,2,i,true)<=rules.damage(i,2,i,false):
			failures += 1
	game.player.position = game.creatures[0].position
	game._interact()
	game._interact()
	if game.roster != [0] or game.berries!=1 or game.creatures[0].visible:
		failures += 1
	game.player.position = game.creatures[1].position
	game._check_habitat()
	await game._battle_action(false,true)
	if game.turn_count != 0:
		failures += 1
	if not game.battle_camera.current or not game.creatures[0].visible:
		failures += 1
	for turn in range(6):
		await game._battle_action(false)
	if game.battle!=-1 or game.levels[0]!=2 or not game.creatures[1].tired:
		failures += 1
	game._interact()
	if not game.roster.has(1):
		failures += 1
	game.player.position = Vector3(0,game.height_at(0,-33),-30)
	if not game._open_path():
		failures += 1
	game.active_species = 0
	# A recruited partner can still train; switching partners cannot consume all encounters.
	game._check_habitat()
	if game.battle != -1:
		failures += 1
	game._begin_training(1)
	await game._battle_action(false,true)
	await game._battle_action(false,true)
	if game.turn_count != 1:
		failures += 1
	for turn in range(6):
		await game._battle_action(false)
	if game.battle!=-1 or game.experience[game.active_species]<=0:
		failures += 1
	game.player.position = Vector3(0,0,4)
	game._check_habitat()
	game.player.position = game.creatures[0].position
	game._check_habitat()
	if game.battle != 0 or game.wild_actor == game.creatures[0]:
		failures += 1
	game._finish_encounter()
	game._check_habitat()
	if game.battle >= 0 or game.creatures[0].visible:
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
	# Simulate a rename with a completed adventure in the old sibling folder.
	var previous_folder := OS.get_user_data_dir().get_base_dir().path_join("Filizya")
	DirAccess.make_dir_recursive_absolute(previous_folder)
	var previous_save := previous_folder.path_join("ashvale-companions-v1.json")
	DirAccess.copy_absolute(ProjectSettings.globalize_path(game.STATE_PATH), previous_save)
	DirAccess.remove_absolute(game.STATE_PATH)
	var migrated: Node = load("res://creature_valley.tscn").instantiate()
	root.add_child(migrated)
	migrated.set_physics_process(false)
	if not migrated.gate_open or migrated.roster != game.roster or migrated.levels[0] != 2:
		failures += 1
	DirAccess.remove_absolute(previous_save)
	DirAccess.remove_absolute(game.STATE_PATH)
	print("AshvaleCompanionsTest failures=",failures)
	quit(0 if failures==0 else 1)
