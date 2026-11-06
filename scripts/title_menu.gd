extends "res://scripts/creatures/valley.gd"

const PLAY_SCENE := "res://creature_valley.tscn"
var continue_button: Button
var new_button: Button
var confirm_reset: ConfirmationDialog
var error_text: Label

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_make_valley()
	_make_companions()
	var vista := Camera3D.new()
	add_child(vista)
	vista.position = Vector3(-6,3.5,5)
	vista.look_at(Vector3(1,1,-8))
	vista.current = true
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var sheet := PanelContainer.new()
	canvas.add_child(sheet)
	sheet.anchor_top = 0.5
	sheet.anchor_bottom = 0.5
	sheet.offset_top = -208
	sheet.offset_bottom = 208
	sheet.offset_left = 60
	sheet.offset_right = 480
	var backdrop := StyleBoxFlat.new()
	backdrop.bg_color = Color("#162b36ed")
	backdrop.set_corner_radius_all(16)
	backdrop.set_content_margin_all(32)
	sheet.add_theme_stylebox_override("panel",backdrop)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	sheet.add_child(column)
	var title := Label.new()
	title.text = "FİLİZYA"
	title.add_theme_font_size_override("font_size",64)
	title.add_theme_color_override("font_color",Color("#ffe6ac"))
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Yoldaşlar Vadisi"
	subtitle.add_theme_font_size_override("font_size",22)
	column.add_child(subtitle)
	continue_button = _menu_button(column,"Devam Et",_start.bind(false))
	continue_button.disabled = not _has_adventure()
	new_button = _menu_button(column,"Yeni Oyun",_request_new)
	_menu_button(column,"Çıkış",get_tree().quit)
	error_text = Label.new()
	column.add_child(error_text)
	confirm_reset = ConfirmationDialog.new()
	confirm_reset.title = "Yeni oyun"
	confirm_reset.dialog_text = "Mevcut ekibin ve keşif ilerlemen yerine yeni bir macera kaydedilsin mi?"
	confirm_reset.ok_button_text = "Baştan başla"
	confirm_reset.cancel_button_text = "Vazgeç"
	confirm_reset.confirmed.connect(_start.bind(true))
	add_child(confirm_reset)
	if continue_button.disabled:
		new_button.grab_focus()
	else:
		continue_button.grab_focus()
	print("Filizya menu ready")

func _menu_button(column: VBoxContainer, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 52
	button.add_theme_font_size_override("font_size",22)
	button.pressed.connect(action)
	column.add_child(button)
	return button

func _has_adventure() -> bool:
	return FileAccess.file_exists(STATE_PATH) or FileAccess.file_exists(_previous_save_path())

func _request_new() -> void:
	if _has_adventure():
		confirm_reset.popup_centered()
	else:
		_start(true)

func _start(fresh: bool) -> void:
	if fresh:
		get_tree().set_meta("filizya_new_game",true)
	var result := get_tree().change_scene_to_file(PLAY_SCENE)
	if result != OK:
		if get_tree().has_meta("filizya_new_game"):
			get_tree().remove_meta("filizya_new_game")
		error_text.text = "Vadi açılamadı."

func _physics_process(_delta: float) -> void:
	pass

func _unhandled_input(_event: InputEvent) -> void:
	pass

func _notification(_what: int) -> void:
	pass
