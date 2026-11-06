extends CanvasLayer

# Ashvale oyun arayuzu: durum cubuklari, saat, hotbar, etkilesim ipucu,
# toplama bildirimleri, envanter + uretim penceresi, ipucu kutusu, yardim, F3.
# Tasarim cozunurlugu 1920x1080; canvas_items/expand ile olceklenir.

const ITEMS := preload("res://scripts/items.gd")
const ITEM_ICON := preload("res://scripts/ui/item_icon.gd")
const SLOT_SCRIPT := preload("res://scripts/ui/inventory_slot.gd")

const ACCENT := Color(0.95, 0.78, 0.42)
const TEXT := Color(0.94, 0.93, 0.9)
const MUTED := Color(0.7, 0.68, 0.64)
const GOOD := Color(0.55, 0.85, 0.45)
const BAD := Color(0.95, 0.42, 0.36)

var inventory: RefCounted
var hint_label: Label
var is_open := false
var selected_slot := 0

var _root: Control
var _health_fill: ColorRect
var _health_text: Label
var _stamina_fill: ColorRect
var _warmth: Label
var _night_goal: Label
var _clock: Label
var _clock_sub: Label
var _hotbar_slots: Array = []
var _grid_slots: Array = []
var _window: Control
var _recipe_list: VBoxContainer
var _recipe_buttons: Array = []
var _detail_icon: Control
var _detail_name: Label
var _detail_desc: Label
var _detail_costs: VBoxContainer
var _craft_button: Button
var _craft_progress: ProgressBar
var _selected_recipe := 0
var _crafting_time := -1.0
var _crafting_recipe: Dictionary = {}
var _toasts: VBoxContainer
var _tooltip: PanelContainer
var _tooltip_name: Label
var _tooltip_body: Label
var _help: Control
var _debug: Label
var _selected_name: Label
var _selected_name_timer := 0.0

func setup(inv: RefCounted) -> void:
	inventory = inv
	layer = 5
	_build()
	inventory.changed.connect(_refresh)
	inventory.item_added.connect(_on_item_added)
	_refresh()

# ---------- kurulum ----------
func _panel_style(alpha := 0.86, radius := 14) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.06, 0.068, alpha)
	style.border_color = Color(1, 1, 1, 0.07)
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 10
	style.set_content_margin_all(18)
	return style

func _label(text: String, font_size: int, color := TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _bar(color: Color) -> Array:
	var back := ColorRect.new()
	back.color = Color(0, 0, 0, 0.45)
	back.custom_minimum_size = Vector2(300, 14)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := ColorRect.new()
	fill.color = color
	fill.size = Vector2(300, 14)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(fill)
	return [back, fill]

func _build() -> void:
	_root = Control.new()
	_root.name = "UIRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# Durum karti (sol ust)
	var status := PanelContainer.new()
	status.name = "StatusPanel"
	status.position = Vector2(32, 28)
	status.add_theme_stylebox_override("panel", _panel_style(0.72))
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(status)
	var status_box := VBoxContainer.new()
	status_box.add_theme_constant_override("separation", 6)
	status.add_child(status_box)
	var title := _label("ASHVALE", 22, ACCENT)
	status_box.add_child(title)
	var health_row := HBoxContainer.new()
	health_row.add_child(_label("CAN", 15, MUTED))
	_health_text = _label("100", 15, TEXT)
	_health_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_health_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	health_row.add_child(_health_text)
	status_box.add_child(health_row)
	var health_bar := _bar(Color(0.86, 0.27, 0.24))
	_health_fill = health_bar[1]
	status_box.add_child(health_bar[0])
	status_box.add_child(_label("DAYANIKLILIK", 15, MUTED))
	var stamina_bar := _bar(Color(0.93, 0.76, 0.3))
	_stamina_fill = stamina_bar[1]
	status_box.add_child(stamina_bar[0])
	_warmth = _label("", 16, TEXT)
	status_box.add_child(_warmth)
	_night_goal = _label("", 16, ACCENT)
	status_box.add_child(_night_goal)

	# Saat (sag ust)
	var clock_panel := PanelContainer.new()
	clock_panel.name = "ClockPanel"
	clock_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	clock_panel.position = Vector2(-212, 28)
	clock_panel.custom_minimum_size = Vector2(180, 0)
	clock_panel.add_theme_stylebox_override("panel", _panel_style(0.72))
	clock_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(clock_panel)
	var clock_box := VBoxContainer.new()
	clock_panel.add_child(clock_box)
	_clock = _label("08:30", 34, TEXT)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_box.add_child(_clock)
	_clock_sub = _label("GÜNDÜZ", 14, MUTED)
	_clock_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_box.add_child(_clock_sub)

	# Hotbar (alt orta)
	var hotbar := HBoxContainer.new()
	hotbar.name = "Hotbar"
	hotbar.add_theme_constant_override("separation", 10)
	# Tam ortada: genislik = 6 yuva + 5 bosluk.
	var hotbar_size: int = inventory.HOTBAR_SIZE
	var hotbar_width: float = 84.0 * hotbar_size + 10.0 * (hotbar_size - 1)
	hotbar.anchor_left = 0.5
	hotbar.anchor_right = 0.5
	hotbar.anchor_top = 1.0
	hotbar.anchor_bottom = 1.0
	hotbar.offset_left = -hotbar_width * 0.5
	hotbar.offset_right = hotbar_width * 0.5
	hotbar.offset_top = -116
	hotbar.offset_bottom = -32
	_root.add_child(hotbar)
	for i in range(inventory.HOTBAR_SIZE):
		var slot := _make_slot(i, str(i + 1))
		hotbar.add_child(slot)
		_hotbar_slots.append(slot)
	_selected_name = _label("", 20, TEXT)
	_place(_selected_name, Vector2(0.5, 1.0), Rect2(-300, -152, 600, 30))
	_selected_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_selected_name)

	# Etkilesim ipucu (hotbar ustu)
	hint_label = _label("", 24, TEXT)
	hint_label.name = "Hint"
	_place(hint_label, Vector2(0.5, 1.0), Rect2(-500, -205, 1000, 40))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	hint_label.add_theme_constant_override("outline_size", 6)
	_root.add_child(hint_label)

	# Toplama bildirimleri (sag)
	_toasts = VBoxContainer.new()
	_toasts.name = "Toasts"
	_place(_toasts, Vector2(1.0, 0.5), Rect2(-300, -40, 270, 300))
	_toasts.add_theme_constant_override("separation", 6)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_toasts)

	# Kontrol ipucu (sol alt)
	var help_hint := _label("[TAB] Envanter & Üretim    [H] Kontroller", 17, Color(1, 1, 1, 0.6))
	_place(help_hint, Vector2(0.0, 1.0), Rect2(32, -48, 600, 30))
	_root.add_child(help_hint)

	_build_window()
	_build_tooltip()
	_build_help()
	_debug = _label("", 15, Color(0.8, 1.0, 0.8))
	_debug.position = Vector2(32, 230)
	_debug.visible = false
	_root.add_child(_debug)

# Bir kontrolu ekrandaki bir capa noktasina gore yerlestirir (cozunurlukten bagimsiz).
func _place(control: Control, anchor: Vector2, rect: Rect2) -> void:
	control.anchor_left = anchor.x
	control.anchor_right = anchor.x
	control.anchor_top = anchor.y
	control.anchor_bottom = anchor.y
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y

func _make_slot(index: int, key: String) -> Panel:
	var slot: Panel = SLOT_SCRIPT.new()
	slot.index = index
	slot.inventory = inventory
	slot.hotbar_key = key
	slot.hovered.connect(_on_slot_hovered)
	slot.unhovered.connect(func(_i: int) -> void: _tooltip.visible = false)
	return slot

func _build_window() -> void:
	_window = Control.new()
	_window.name = "InventoryWindow"
	_window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_window.visible = false
	_root.add_child(_window)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_window.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-690, -350)
	panel.custom_minimum_size = Vector2(1380, 640)
	panel.add_theme_stylebox_override("panel", _panel_style(0.94, 18))
	_window.add_child(panel)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	panel.add_child(columns)

	# Envanter izgarasi
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 12)
	columns.add_child(left)
	left.add_child(_label("ENVANTER", 26, ACCENT))
	left.add_child(_label("Sürükleyip bırakarak düzenle. İlk sıra hızlı seçim çubuğudur.", 15, MUTED))
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	left.add_child(grid)
	for i in range(inventory.SLOT_COUNT):
		var slot := _make_slot(i, str(i + 1) if i < inventory.HOTBAR_SIZE else "")
		grid.add_child(slot)
		_grid_slots.append(slot)

	var divider := ColorRect.new()
	divider.color = Color(1, 1, 1, 0.06)
	divider.custom_minimum_size = Vector2(2, 0)
	columns.add_child(divider)

	# Uretim listesi
	var middle := VBoxContainer.new()
	middle.add_theme_constant_override("separation", 12)
	middle.custom_minimum_size = Vector2(330, 0)
	columns.add_child(middle)
	middle.add_child(_label("ÜRETİM", 26, ACCENT))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(330, 530)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	middle.add_child(scroll)
	_recipe_list = VBoxContainer.new()
	_recipe_list.add_theme_constant_override("separation", 6)
	_recipe_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_recipe_list)
	for i in range(ITEMS.RECIPES.size()):
		var recipe: Dictionary = ITEMS.RECIPES[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(310, 58)
		button.toggle_mode = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = ITEMS.display_name(recipe["result"]) + ("  ×%d" % recipe["count"] if int(recipe["count"]) > 1 else "")
		button.add_theme_font_size_override("font_size", 19)
		for state in ["normal", "hover", "pressed", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.1, 0.11, 0.12, 0.9) if state == "normal" else Color(0.17, 0.16, 0.13, 0.95)
			style.border_color = ACCENT if state == "pressed" else Color(1, 1, 1, 0.06)
			style.set_border_width_all(2 if state == "pressed" else 1)
			style.set_corner_radius_all(10)
			style.content_margin_left = 68 # ikon icin yer
			button.add_theme_stylebox_override(state, style)
		var icon := ITEM_ICON.new()
		icon.item_id = recipe["result"]
		icon.position = Vector2(8, 5)
		icon.size = Vector2(48, 48)
		button.add_child(icon)
		var index := i
		button.pressed.connect(func() -> void: select_recipe(index))
		_recipe_list.add_child(button)
		_recipe_buttons.append(button)

	# Ayrinti
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	right.add_child(head)
	_detail_icon = ITEM_ICON.new()
	_detail_icon.custom_minimum_size = Vector2(96, 96)
	head.add_child(_detail_icon)
	var head_text := VBoxContainer.new()
	head.add_child(head_text)
	_detail_name = _label("", 28, TEXT)
	head_text.add_child(_detail_name)
	_detail_desc = _label("", 16, MUTED)
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_desc.custom_minimum_size = Vector2(260, 0)
	head_text.add_child(_detail_desc)
	right.add_child(_label("GEREKENLER", 16, ACCENT))
	_detail_costs = VBoxContainer.new()
	_detail_costs.add_theme_constant_override("separation", 8)
	right.add_child(_detail_costs)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer)
	_craft_progress = ProgressBar.new()
	_craft_progress.show_percentage = false
	_craft_progress.custom_minimum_size = Vector2(0, 10)
	_craft_progress.max_value = 1.0
	_craft_progress.visible = false
	right.add_child(_craft_progress)
	_craft_button = Button.new()
	_craft_button.text = "ÜRET"
	_craft_button.custom_minimum_size = Vector2(0, 58)
	_craft_button.add_theme_font_size_override("font_size", 22)
	var craft_style := StyleBoxFlat.new()
	craft_style.bg_color = Color(0.62, 0.47, 0.22)
	craft_style.set_corner_radius_all(10)
	_craft_button.add_theme_stylebox_override("normal", craft_style)
	var craft_hover := craft_style.duplicate() as StyleBoxFlat
	craft_hover.bg_color = Color(0.74, 0.57, 0.28)
	_craft_button.add_theme_stylebox_override("hover", craft_hover)
	var craft_disabled := craft_style.duplicate() as StyleBoxFlat
	craft_disabled.bg_color = Color(0.2, 0.2, 0.2)
	_craft_button.add_theme_stylebox_override("disabled", craft_disabled)
	_craft_button.pressed.connect(start_craft)
	right.add_child(_craft_button)
	select_recipe(0)

func _build_tooltip() -> void:
	_tooltip = PanelContainer.new()
	_tooltip.name = "Tooltip"
	_tooltip.add_theme_stylebox_override("panel", _panel_style(0.96, 10))
	_tooltip.visible = false
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.z_index = 10
	_root.add_child(_tooltip)
	var box := VBoxContainer.new()
	_tooltip.add_child(box)
	_tooltip_name = _label("", 20, ACCENT)
	box.add_child(_tooltip_name)
	_tooltip_body = _label("", 15, TEXT)
	_tooltip_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_body.custom_minimum_size = Vector2(300, 0)
	box.add_child(_tooltip_body)

func _build_help() -> void:
	_help = PanelContainer.new()
	_help.name = "Help"
	_help.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_help.position = Vector2(32, -220)
	_help.add_theme_stylebox_override("panel", _panel_style(0.9))
	_help.visible = false
	_root.add_child(_help)
	var text := _label("", 17, TEXT)
	text.text = "KONTROLLER\n\nWASD  Hareket\nSHIFT  Koş\nSPACE  Zıpla\nFARE  Kamera / Tekerlek: yakınlaştır\nSOL TIK  Kullan (kes, kaz, kur)\n1–6  Hızlı seçim\nE  Topla / Ateşe odun ekle\nTAB  Envanter & Üretim\nT  Saati 1 saat ileri sar\nR  Öldükten sonra yeniden doğ\nF3  Hata ayıklama bilgisi\nF11  Tam ekran\nESC  İmleç"
	_help.add_child(text)

# ---------- guncelleme ----------
func _process(delta: float) -> void:
	if _tooltip.visible:
		_tooltip.position = _root.get_local_mouse_position() + Vector2(22, 22)
	if _crafting_time >= 0.0:
		_crafting_time += delta
		var duration := float(_crafting_recipe.get("time", 1.0))
		_craft_progress.value = clampf(_crafting_time / duration, 0.0, 1.0)
		if _crafting_time >= duration:
			_finish_craft()
	if _selected_name_timer > 0.0:
		_selected_name_timer -= delta
		_selected_name.modulate.a = clampf(_selected_name_timer / 0.5, 0.0, 1.0)

func _refresh() -> void:
	for slot in _hotbar_slots + _grid_slots:
		slot.refresh()
	_refresh_recipes()

func set_selected(index: int) -> void:
	selected_slot = index
	for i in range(_hotbar_slots.size()):
		_hotbar_slots[i].selected = i == index
		_grid_slots[i].selected = i == index
	var id: String = inventory.item_at(index)
	_selected_name.text = ITEMS.display_name(id) if not id.is_empty() else ""
	_selected_name_timer = 2.0

func set_status(health: float, max_health: float, stamina: float) -> void:
	_health_fill.size.x = 300.0 * clampf(health / max_health, 0.0, 1.0)
	_health_text.text = str(int(ceilf(health)))
	_stamina_fill.size.x = 300.0 * clampf(stamina / 100.0, 0.0, 1.0)

func set_survival(warmth: float, goal: String) -> void:
	_warmth.text = "Vücut sıcaklığı  %d%%" % ceili(warmth)
	_warmth.modulate = BAD if warmth < 25 else TEXT
	_night_goal.text = goal
	_night_goal.visible = not goal.is_empty()

func set_clock(text: String, night: bool) -> void:
	_clock.text = text
	_clock_sub.text = "GECE" if night else "GÜNDÜZ"
	_clock_sub.add_theme_color_override("font_color", Color(0.6, 0.7, 1.0) if night else MUTED)

func set_hint(text: String) -> void:
	hint_label.text = text

func set_debug(text: String) -> void:
	_debug.text = text

func toggle_debug() -> void:
	_debug.visible = not _debug.visible

func toggle_help() -> void:
	_help.visible = not _help.visible

func toggle_inventory() -> bool:
	is_open = not is_open
	_window.visible = is_open
	_tooltip.visible = false
	if is_open:
		_refresh()
	return is_open

func toast(text: String, item_id := "", color := TEXT) -> void:
	var panel := PanelContainer.new()
	var style := _panel_style(0.82, 10)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	if not item_id.is_empty():
		var icon := ITEM_ICON.new()
		icon.item_id = item_id
		icon.custom_minimum_size = Vector2(34, 34)
		row.add_child(icon)
	var label := _label(text, 18, color)
	row.add_child(label)
	_toasts.add_child(panel)
	while _toasts.get_child_count() > 5:
		_toasts.get_child(0).queue_free()
		_toasts.remove_child(_toasts.get_child(0))
	panel.modulate.a = 0.0
	var tween := panel.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.15)
	tween.tween_interval(2.4)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(panel.queue_free)

func _on_item_added(id: String, amount: int) -> void:
	toast("+%d  %s" % [amount, ITEMS.display_name(id)], id)

func _on_slot_hovered(index: int) -> void:
	var id: String = inventory.item_at(index)
	if id.is_empty():
		_tooltip.visible = false
		return
	var data := ITEMS.info(id)
	_tooltip_name.text = String(data.get("name", id))
	var body := "%s\n%s" % [String(data.get("category", "")), String(data.get("description", ""))]
	if data.has("power"):
		body += "\nGüç: %.1f   Seviye: %d" % [float(data["power"]), int(data.get("tier", 0))]
	_tooltip_body.text = body
	_tooltip.visible = true

# ---------- uretim ----------
func select_recipe(index: int) -> void:
	_selected_recipe = clampi(index, 0, ITEMS.RECIPES.size() - 1)
	for i in range(_recipe_buttons.size()):
		_recipe_buttons[i].button_pressed = i == _selected_recipe
	_refresh_recipes()

func _refresh_recipes() -> void:
	if _recipe_buttons.is_empty():
		return
	for i in range(_recipe_buttons.size()):
		var ok: bool = inventory.can_craft(ITEMS.RECIPES[i])
		_recipe_buttons[i].modulate = Color(1, 1, 1) if ok else Color(0.62, 0.6, 0.58)
	var recipe: Dictionary = ITEMS.RECIPES[_selected_recipe]
	var result := String(recipe["result"])
	_detail_icon.item_id = result
	_detail_name.text = ITEMS.display_name(result) + ("  ×%d" % recipe["count"] if int(recipe["count"]) > 1 else "")
	_detail_desc.text = String(ITEMS.info(result).get("description", ""))
	for child in _detail_costs.get_children():
		child.queue_free()
	for id in recipe["cost"]:
		var need := int(recipe["cost"][id])
		var have: int = inventory.count(String(id))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var icon := ITEM_ICON.new()
		icon.item_id = String(id)
		icon.custom_minimum_size = Vector2(40, 40)
		row.add_child(icon)
		var name_label := _label(ITEMS.display_name(String(id)), 19, TEXT)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		row.add_child(_label("%d / %d" % [have, need], 19, GOOD if have >= need else BAD))
		_detail_costs.add_child(row)
	_craft_button.disabled = _crafting_time >= 0.0 or not inventory.can_craft(recipe)
	_craft_button.text = "ÜRETİLİYOR…" if _crafting_time >= 0.0 else "ÜRET"

func start_craft() -> bool:
	var recipe: Dictionary = ITEMS.RECIPES[_selected_recipe]
	if _crafting_time >= 0.0 or not inventory.can_craft(recipe):
		return false
	_crafting_recipe = recipe
	_crafting_time = 0.0
	_craft_progress.value = 0.0
	_craft_progress.visible = true
	_refresh_recipes()
	return true

func _finish_craft() -> void:
	var recipe := _crafting_recipe
	_crafting_time = -1.0
	_craft_progress.visible = false
	if not inventory.craft(recipe):
		toast("Üretilemedi: malzeme ya da yer yok", "", BAD)
	_refresh_recipes()

func is_crafting() -> bool:
	return _crafting_time >= 0.0
