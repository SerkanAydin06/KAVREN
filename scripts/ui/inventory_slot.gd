extends Panel

# Tek envanter yuvasi: ikon, miktar, hotbar tus numarasi, secim cercevesi.
# Surukle-birak ile yuvalar arasinda esya tasinir / yigınlar birlesir.

signal hovered(index: int)
signal unhovered(index: int)
signal clicked(index: int)

const ITEM_ICON := preload("res://scripts/ui/item_icon.gd")

var index := 0
var inventory: RefCounted
var hotbar_key := ""
var selected := false:
	set(value):
		selected = value
		_apply_style()

var _icon: Control
var _count: Label
var _key: Label
var _style_normal: StyleBoxFlat
var _style_selected: StyleBoxFlat
var _style_hover: StyleBoxFlat
var _hover := false

func _ready() -> void:
	custom_minimum_size = Vector2(84, 84)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_style_normal = _make_style(Color(0.09, 0.1, 0.11, 0.82), Color(1, 1, 1, 0.08), 2)
	_style_hover = _make_style(Color(0.14, 0.15, 0.16, 0.9), Color(0.85, 0.72, 0.45, 0.5), 2)
	_style_selected = _make_style(Color(0.16, 0.14, 0.1, 0.92), Color(0.95, 0.78, 0.42, 1.0), 3)
	_icon = ITEM_ICON.new()
	_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_icon.offset_left = 10
	_icon.offset_top = 8
	_icon.offset_right = -10
	_icon.offset_bottom = -12
	add_child(_icon)
	_count = Label.new()
	_count.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_count.offset_left = -50
	_count.offset_top = -30
	_count.offset_right = -7
	_count.offset_bottom = -3
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count.add_theme_font_size_override("font_size", 19)
	_count.add_theme_color_override("font_outline_color", Color.BLACK)
	_count.add_theme_constant_override("outline_size", 5)
	add_child(_count)
	_key = Label.new()
	_key.position = Vector2(7, 3)
	_key.add_theme_font_size_override("font_size", 15)
	_key.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	_key.text = hotbar_key
	add_child(_key)
	mouse_entered.connect(func() -> void:
		_hover = true
		_apply_style()
		hovered.emit(index))
	mouse_exited.connect(func() -> void:
		_hover = false
		_apply_style()
		unhovered.emit(index))
	_apply_style()
	refresh()

func _make_style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 4
	return style

func _apply_style() -> void:
	if _style_normal == null:
		return
	add_theme_stylebox_override("panel", _style_selected if selected else (_style_hover if _hover else _style_normal))

func refresh() -> void:
	if _icon == null or inventory == null:
		return
	var slot: Variant = inventory.get_slot(index)
	_icon.item_id = String(slot["id"]) if slot != null else ""
	var amount := int(slot["count"]) if slot != null else 0
	_count.text = str(amount) if amount > 1 else ""

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(index)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if inventory == null or inventory.get_slot(index) == null:
		return null
	var preview := ITEM_ICON.new()
	preview.item_id = inventory.item_at(index)
	preview.size = Vector2(72, 72)
	preview.modulate = Color(1, 1, 1, 0.85)
	var holder := Control.new()
	holder.add_child(preview)
	preview.position = -preview.size * 0.5
	set_drag_preview(holder)
	return {"ashvale_slot": index}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data as Dictionary).has("ashvale_slot")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	inventory.move(int(data["ashvale_slot"]), index)
