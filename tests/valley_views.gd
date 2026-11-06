extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.atmosphere.time_flows = false
	scene.ui.hide()
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.current = true
	var views := [
		["camp", Vector3(0, 2.8, 5), Vector3(0, 3.4, -45), 8.5],
		["trail", Vector3(6, 2.5, -27), Vector3(0, 4, -73), 11.0],
		["mine", Vector3(-7, 2.8, -58), Vector3(0, 5, -78), 16.5],
	]
	var folder := "user://valley-views"
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		quit(1)
		return
	for view in views:
		scene.atmosphere.set_hour(view[3])
		camera.position = view[1]
		camera.look_at(view[2])
		for frame in range(12):
			await RenderingServer.frame_post_draw
		var frame_image := root.get_texture().get_image()
		if frame_image == null or frame_image.save_png(folder + "/" + view[0] + ".png") != OK:
			quit(1)
			return
	print("Valley views: ", ProjectSettings.globalize_path(folder))
	quit()
