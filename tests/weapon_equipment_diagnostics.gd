extends SceneTree

# Verify the actual wielded axe is attached to the Mixamo hand with metres,
# not inadvertently shrunk with the imported centimetre-scale character.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	var failures := 0
	var axe: Node3D = game.equipped_axe
	var mount: Node3D = game.axe_attachment
	if axe == null or mount == null or not axe.visible or not axe.is_inside_tree():
		print("AshvaleWeaponTest missing visible equipped axe")
		quit(1)
		return
	var mesh_count := 0
	var total_faces := 0
	var pending: Array[Node] = [axe]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		if current is MeshInstance3D:
			mesh_count += 1
			var part: MeshInstance3D = current as MeshInstance3D
			if part.mesh != null:
				total_faces += int(part.mesh.get_faces().size() / 3)
		for child in current.get_children():
			pending.append(child)
	var model_key := String(axe.get_meta("model_key", "procedural"))
	var world_scale: Vector3 = axe.global_transform.basis.get_scale()
	var hand_distance := axe.global_position.distance_to(mount.global_position)
	var hand_name := ""
	if mount is BoneAttachment3D:
		hand_name = (mount as BoneAttachment3D).bone_name
	else:
		failures += 1 # Char1 includes a working right-hand bone.
	if not hand_name.to_lower().ends_with("righthand"):
		failures += 1
	if world_scale.x < 0.60 or world_scale.x > 1.45:
		failures += 1
	if hand_distance > 0.35:
		failures += 1
	# Meshy hand_axe modeli kullanilmali; prosedurel balta sadece yedek.
	if model_key != "hand_axe" or mesh_count < 1 or total_faces < 1000:
		failures += 1
	# Kazma da ayni ele takili, ama balta seciliyken gizli olmali.
	var pickaxe: Node3D = game.equipped_pickaxe
	if pickaxe == null or pickaxe.get_parent() != mount or pickaxe.visible:
		failures += 1
	# Sag el yumruk yapmali: parmak kivirma modifier'i iskelette ve aktif.
	var grip: Node = game.hand_grip
	var curled := 0
	if grip == null or grip.get_parent() != game.skeleton:
		failures += 1
	else:
		curled = grip.curled_bone_count()
		if curled < 12:
			failures += 1
	# Kavrama noktasi avuc icinde: el kemiginden parmak koklerine dogru,
	# bilegin gerisinde veya parmak uclarinin otesinde degil.
	var local_grip: Vector3 = axe.position
	if local_grip.y <= 0.0 or local_grip.length() > 0.6:
		failures += 1
	print("AshvaleWeaponTest grip curled_bones=", curled, " grip_local=", local_grip)
	print("AshvaleWeaponTest bone=", hand_name, " world_scale=", world_scale, " hand_distance=", hand_distance, " model=", model_key, " meshes=", mesh_count, " triangles=", total_faces, " failures=", failures)
	quit(1 if failures > 0 else 0)
