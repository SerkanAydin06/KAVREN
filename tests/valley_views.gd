extends SceneTree
func _initialize() -> void: call_deferred("_capture")
func _capture() -> void:
	var menu: Node = load("res://scenes/title_menu.tscn").instantiate()
	root.add_child(menu)
	for frame in range(12):
		await RenderingServer.frame_post_draw
	var menu_folder := "user://valley-views"
	DirAccess.make_dir_recursive_absolute(menu_folder)
	if root.get_texture().get_image().save_png(menu_folder+"/menu.png") != OK:
		quit(1)
		return
	menu.free()
	var scene: Node = load("res://creature_valley.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.current = true
	var folder := "user://valley-views"
	DirAccess.make_dir_recursive_absolute(folder)
	var views := [
		["companions-valley",Vector3(-5,5,12),Vector3(0,1.1,-8)],
		["starter-thicket",Vector3(-2,2.3,0.3),Vector3(-3,0.9,-3)],
		["reed-pool",Vector3(11,4,-8),Vector3(9,2,-13)],
		["rocky-verge",Vector3(-5,5,-18),Vector3(-8,3.2,-22)],
		["passage",Vector3(0,7,-25),Vector3(0,1,-39)],
	]
	for view in views:
		camera.position=view[1]
		camera.look_at(view[2])
		for i in range(12):
			await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		if picture==null or picture.save_png(folder+"/"+view[0]+".png")!=OK:
			quit(1)
			return
	scene.player.position = scene.creatures[0].position
	scene._interact()
	scene._interact()
	scene.player.position = scene.creatures[1].position+Vector3(0,0,1.5)
	scene._interact()
	scene._refresh_interface()
	scene.battle_camera.current = true
	for i in range(12):
		await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(folder+"/training.png")!=OK:
		quit(1)
		return
	quit()
