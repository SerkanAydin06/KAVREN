extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var valley: Node = load("res://creature_valley.tscn").instantiate()
	root.add_child(valley)
	valley.set_physics_process(false)
	valley.atmosphere.time_flows = false
	var terrain: MeshInstance3D = valley.get_node("ValleyGround").get_child(0)
	if RenderingServer.get_current_rendering_method() != "forward_plus" or terrain.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
		quit(1)
		return
	var camera := Camera3D.new()
	valley.add_child(camera)
	camera.position = Vector3(4,4.2,7)
	camera.look_at(Vector3(-2,0,-3))
	camera.current = true
	var folder := "user://valley-views"
	DirAccess.make_dir_recursive_absolute(folder)
	# Keep the sky, light, geometry and camera identical between captures.
	paused = true
	for baseline in [true,false]:
		terrain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if baseline else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for frame in range(20):
			await RenderingServer.frame_post_draw
		var filename := "ground-before.png" if baseline else "ground-after.png"
		var picture := root.get_texture().get_image()
		if picture == null or picture.save_png(folder.path_join(filename)) != OK:
			quit(1)
			return
	quit()
