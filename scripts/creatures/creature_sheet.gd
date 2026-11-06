extends ColorRect

signal learn_requested(species: int, path: int, depth: int)
signal closed
const RULES := preload("res://scripts/creatures/development.gd")
const CREATURE := preload("res://scripts/creatures/companion.gd")
var game: Node
var selected := 0
var body := VBoxContainer.new()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color("#0d1922e9")
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.add_child(body)
	body.custom_minimum_size.x = 1020
	body.add_theme_constant_override("separation",16)
	hide()

func open_for(index: int) -> void:
	selected = index
	refresh()
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _label(parent: Control, value: String, size_px: int, tint: Color) -> void:
	var line := Label.new()
	line.text = value
	line.add_theme_font_size_override("font_size",size_px)
	line.add_theme_color_override("font_color",tint)
	parent.add_child(line)

func refresh() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	var tabs := HBoxContainer.new()
	body.add_child(tabs)
	for index: int in game.roster:
		var tab := Button.new()
		tab.text = CREATURE.SPECIES[index].name
		tab.disabled = index == selected
		tab.pressed.connect(open_for.bind(index))
		tabs.add_child(tab)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(spacer)
	var close_button := Button.new()
	close_button.text = "Kapat  [G / Esc]"
	close_button.pressed.connect(func(): closed.emit())
	tabs.add_child(close_button)
	var level: int = game.levels[selected]
	var known: Array = game.learned[selected]
	var gold := Color("#ffe3a5")
	_label(body,"%s  ·  %s  ·  Sv. %d" % [CREATURE.SPECIES[selected].name,CREATURE.ELEMENT[selected],level],33,gold)
	_label(body,"Azami can %d     Saldırı %d     Zırh %d     Deneyim %d / %d" % [game.ally_hp(selected),CREATURE.damage(selected,level,selected,false)+RULES.bonus(selected,known,"power"),RULES.bonus(selected,known,"armor"),game.experience[selected],level*10],22,Color.WHITE)
	_label(body,"%s  ·  %s (%s)" % [CREATURE.SPECIES[selected].move,CREATURE.SPECIAL[selected],"hazır" if level >= 2 else "Sv. 2"],19,Color("#b6d6cb"))
	_label(body,"Gelişim ağacı   ·   %d puan" % RULES.points(level,known,selected),26,gold)
	_label(body,"Yakalamada ve 2–8. seviyelerde birer puan kazanırsın. Son kademede tek uzmanlık seçilir.",18,Color.WHITE)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation",24)
	body.add_child(columns)
	for path in range(2):
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		columns.add_child(column)
		_label(column,RULES.TITLES[selected][path],23,gold)
		for depth in range(3):
			var item: Dictionary = RULES.PATHS[selected][path][depth]
			var button := Button.new()
			var kind := "Aktif [%d]" % (4+path) if depth == 1 else "Pasif"
			var state := "%d puan" % RULES.COST[depth]
			if item.id in known:
				state = "Öğrenildi"
			elif depth == 2 and RULES.PATHS[selected][1-path][2].id in known:
				state = "Diğer uzmanlık seçildi"
			elif depth > 0 and RULES.PATHS[selected][path][depth-1].id not in known:
				state = "Önce " + str(RULES.PATHS[selected][path][depth-1].name)
			button.text = "%s · %s\n%s\n%s" % [item.name,kind,item.detail,state]
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.custom_minimum_size = Vector2(490,96)
			button.disabled = not RULES.available(selected,level,known,path,depth)
			button.pressed.connect(func(): learn_requested.emit(selected,path,depth))
			column.add_child(button)
