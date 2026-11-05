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
	for child in axe.get_children():
		if child is MeshInstance3D:
			mesh_count += 1
			var part: MeshInstance3D = child as MeshInstance3D
			if part.mesh != null:
				total_faces += int(part.mesh.get_faces().size() / 3)
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
	if mesh_count < 5 or total_faces < 15:
		failures += 1
	if axe.get_node_or_null("Handle") == null or axe.get_node_or_null("AxeHead") == null or axe.get_node_or_null("CuttingEdge") == null:
		failures += 1
	print("AshvaleWeaponTest bone=", hand_name, " world_scale=", world_scale, " hand_distance=", hand_distance, " meshes=", mesh_count, " triangles=", total_faces, " failures=", failures)
	quit(1 if failures > 0 else 0)
