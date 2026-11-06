extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# The workflow supplies an empty XDG_DATA_HOME for this real scene transition test.
	if change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene")) != OK:
		quit(1)
		return
	await scene_changed
	var failures := 0
	if not current_scene.continue_button.disabled:
		failures += 1
	current_scene.new_button.pressed.emit()
	await scene_changed
	await process_frame
	if current_scene.roster.size() != 0:
		failures += 1
	current_scene._bond(0)
	current_scene._checkpoint_creatures()
	change_scene_to_file("res://scenes/title_menu.tscn")
	await scene_changed
	current_scene.new_button.pressed.emit()
	if not current_scene.confirm_reset.visible:
		failures += 1
	current_scene.confirm_reset.hide()
	current_scene.continue_button.pressed.emit()
	await scene_changed
	if not current_scene.roster.has(0):
		failures += 1
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	current_scene._unhandled_input(esc)
	await scene_changed
	current_scene.new_button.pressed.emit()
	current_scene.confirm_reset.confirmed.emit()
	await scene_changed
	await process_frame
	if not current_scene.roster.is_empty():
		failures += 1
	change_scene_to_file("res://scenes/title_menu.tscn")
	await scene_changed
	current_scene.continue_button.pressed.emit()
	await scene_changed
	if not current_scene.roster.is_empty():
		failures += 1
	print("FilizyaMenuTest failures=",failures)
	quit(1 if failures else 0)
