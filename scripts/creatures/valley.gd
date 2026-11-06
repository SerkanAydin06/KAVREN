extends "res://scripts/main.gd"

const COMPANION := preload("res://scripts/creatures/companion.gd")
const STATE_PATH := "user://ashvale-companions-v1.json"
const RADIUS := 60.0
var creatures: Array[Node3D] = []
var berries := 3
var roster: Array[int] = []
var levels := [1,1,1]
var experience := [0,0,0]
var active_species := 0
var gate_open := false
var discovered := false
var battle := -1
var resolving := false
var battle_camera: Camera3D
var ally_origin := Vector3.ZERO
var combat_card: PanelContainer
var combat_text: Label
var field_card: PanelContainer
var ally_meter: ProgressBar
var foe_meter: ProgressBar
var friend_energy := 30
var rival_energy := 24
var turn_count := 0
var journal: Label
var prompt: Label
var panel: Label
var note := "Filizik yapraklı kulaklarını sana çevirdi. Yaklaş ve E ile tanış."
var bushes: Array[Node3D] = []
var gate: StaticBody3D
var gate_visual: Node3D
var save_timer := 0.0
var progress_writable := true

func _ready() -> void:
	_make_valley()
	_make_player()
	_make_camera()
	player.position = Vector3(0,0.2,4)
	_make_companions()
	_make_interface()
	_load_progress()
	_refresh_interface()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print("AshvaleCompanions ready: 3 species, rolling valley, friendship and exploration")

static func height_at(x: float, z: float) -> float:
	var ridge := 2.7*exp(-pow((z+21.0)/11.0,2.0))
	var side := 1.4*sin(x*0.075)*sin(z*0.055)
	var clearing := smoothstep(7.0,17.0,Vector2(x,z).length())
	return (ridge+side)*clearing

func _make_valley() -> void:
	atmosphere = ATMOSPHERE_SCRIPT.new()
	add_child(atmosphere)
	atmosphere.set_hour(10.0)
	atmosphere.time_flows = false
	_make_horizon()
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 80
	var step_size := RADIUS*2/n
	for z in range(n):
		for x in range(n):
			var a := Vector2(-RADIUS+x*step_size,-RADIUS+z*step_size)
			var b := a+Vector2(step_size,0)
			var c := a+Vector2(0,step_size)
			var d := a+Vector2(step_size,step_size)
			for q in [a,b,c,b,d,c]:
				tool.add_vertex(Vector3(q.x,height_at(q.x,q.y),q.y))
	tool.generate_normals()
	tool.index()
	var mesh := tool.commit()
	var ground := StaticBody3D.new()
	ground.name = "ValleyGround"
	add_child(ground)
	var display := MeshInstance3D.new()
	display.mesh = mesh
	var mat := ShaderMaterial.new()
	mat.shader = GROUND_SHADER
	mat.set_shader_parameter("ground_albedo",GROUND_ALBEDO)
	mat.set_shader_parameter("camp_center",Vector2(0,3))
	mat.set_shader_parameter("mine_entry",Vector2(0,-44))
	display.material_override = mat
	ground.add_child(display)
	var collider := CollisionShape3D.new()
	collider.shape = mesh.create_trimesh_shape()
	ground.add_child(collider)
	for i in range(26):
		var angle := i*TAU/26
		var pos := Vector3(cos(angle)*(17+i%4*5),0,sin(angle)*(26+i%3*4))
		if pos.z < -22 and absf(pos.x)<10:
			pos.x += 13
		pos.y = height_at(pos.x,pos.z)
		var tree := STYLIZED_PREVIEW_SCENE.tree_visual(i%3==0)
		tree.position = pos
		tree.scale *= 0.68+float(i%3)*0.07
		add_child(tree)
		_solid(pos+Vector3(0,1,0),Vector3(0.65,2,0.65),Color("#70513c"),false)
	for i in range(3):
		var shrub := Node3D.new()
		shrub.position = Vector3(5+i*3,0,1-i*3)
		shrub.position.y = height_at(shrub.position.x,shrub.position.z)
		add_child(shrub)
		var mesh_node := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.8
		sphere.height = 1.2
		mesh_node.mesh = sphere
		mesh_node.position.y = 0.5
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#6da862")
		mesh_node.material_override = material
		shrub.add_child(mesh_node)
		bushes.append(shrub)
	# A short root barrier has two side banks so the opening is unambiguous.
	# The newly opened meadow has a visible reward beyond the rise.
	for i in range(38):
		var x := sin(i*2.399)*float(3+i%9)
		var z := -43.0+cos(i*2.399)*float(2+i%4)
		_prop_blob(Vector3(x,height_at(x,z)+0.22,z),Vector3(0.19,0.22,0.19),[Color("#ffd275"),Color("#efadb5"),Color("#c3b2f0")][i%3])
	_prop_blob(Vector3(10,height_at(10,-13)+0.03,-13),Vector3(3.3,0.08,2.5),Color("#78ced9"))
	for i in range(5):
		var pos := Vector3(-9+i%3,0,-22+i%2)
		pos.y = height_at(pos.x,pos.z)+0.3
		_prop_blob(pos,Vector3(0.7,0.5,0.6),Color("#a9a2b2"))
	var gate_y := height_at(0,-33)
	for side in [-1,1]:
		_solid(Vector3(side*32,gate_y+1.3,-33),Vector3(55,2.6,2),Color("#739d76"))
	gate = _solid(Vector3(0,gate_y+1.2,-33),Vector3(9,2.4,0.7),Color("#41865b"),false)
	gate_visual = gate
	for i in range(7):
		var vine := _prop_blob(Vector3(-3.7+i*1.2,gate_y+1.1,-33),Vector3(0.65,1.4,0.45),Color("#75ad67"))
		var local := vine.transform
		vine.reparent(gate)
		vine.global_transform = local
	for side in [-1,1]:
		for i in range(9):
			_prop_blob(Vector3(side*(7.5+i*5.3),gate_y+1.4,-33),Vector3(3.5,1.8,1.6),Color("#81ac77"))
	_solid(Vector3(-5.1,gate_y+2,-33),Vector3(0.65,4,0.8),Color("#86634c"))
	_solid(Vector3(5.1,gate_y+2,-33),Vector3(0.65,4,0.8),Color("#86634c"))

func _make_horizon() -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(72):
		var a := i*TAU/72
		var b := (i+1)*TAU/72
		var pa := Vector3(cos(a)*95,18+6*sin(a*5)+3*cos(a*9),sin(a)*95)
		var pb := Vector3(cos(b)*95,18+6*sin(b*5)+3*cos(b*9),sin(b)*95)
		var foot_a := Vector3(pa.x,-6,pa.z)*0.85
		var foot_b := Vector3(pb.x,-6,pb.z)*0.85
		for vertex in [foot_a,pb,pa,foot_a,foot_b,pb]:
			tool.add_vertex(vertex)
	tool.generate_normals()
	var ridge := MeshInstance3D.new()
	ridge.mesh = tool.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#8bb6bd")
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	ridge.material_override = mat
	ridge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ridge)

func _prop_blob(pos: Vector3, dimensions: Vector3, tint: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radial_segments = 10
	mesh.rings = 5
	node.mesh = mesh
	node.position = pos
	node.scale = dimensions
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	node.material_override = mat
	add_child(node)
	return node

func _solid(pos: Vector3, size_vector: Vector3, tint: Color, visible_mesh := true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
	var shape := BoxShape3D.new()
	shape.size = size_vector
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	if visible_mesh:
		var box := BoxMesh.new()
		box.size = size_vector
		var display := MeshInstance3D.new()
		display.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = tint
		mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		display.material_override = mat
		body.add_child(display)
	return body

func _make_companions() -> void:
	for i in range(3):
		var creature := COMPANION.new()
		creature.species = i
		var locations := [Vector3(-3,0,-3),Vector3(9,0,-13),Vector3(-8,0,-22)]
		creature.position = locations[i]
		creature.position.y = height_at(creature.position.x,creature.position.z)
		add_child(creature)
		creatures.append(creature)

func _make_interface() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var frame := PanelContainer.new()
	field_card = frame
	frame.position = Vector2(24,22)
	frame.custom_minimum_size.x = 610
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035,0.09,0.13,0.86)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(18)
	frame.add_theme_stylebox_override("panel",style)
	canvas.add_child(frame)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",10)
	frame.add_child(stack)
	journal = Label.new()
	journal.add_theme_font_size_override("font_size",23)
	journal.add_theme_color_override("font_color",Color("#ffe2a0"))
	stack.add_child(journal)
	panel = Label.new()
	panel.custom_minimum_size.x = 574
	panel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_theme_font_size_override("font_size",18)
	stack.add_child(panel)
	combat_card = PanelContainer.new()
	combat_card.anchor_left = 0.05
	combat_card.anchor_right = 0.95
	combat_card.anchor_top = 1.0
	combat_card.anchor_bottom = 1.0
	combat_card.offset_top = -200
	combat_card.offset_bottom = -26
	combat_card.add_theme_stylebox_override("panel",style)
	canvas.add_child(combat_card)
	combat_text = Label.new()
	combat_text.add_theme_font_size_override("font_size",22)
	combat_text.add_theme_color_override("font_color",Color("#ffdfac"))
	var battle_stack := VBoxContainer.new()
	combat_card.add_child(battle_stack)
	var meters := HBoxContainer.new()
	meters.add_theme_constant_override("separation",30)
	battle_stack.add_child(meters)
	ally_meter = _strength_meter(meters,Color("#6ebaa7"))
	foe_meter = _strength_meter(meters,Color("#d78a69"))
	battle_stack.add_child(combat_text)
	combat_card.hide()
	prompt = Label.new()
	prompt.position = Vector2(28,740)
	prompt.add_theme_font_size_override("font_size",23)
	prompt.add_theme_color_override("font_outline_color",Color("#183b46"))
	prompt.add_theme_constant_override("outline_size",6)
	canvas.add_child(prompt)

func _strength_meter(row: HBoxContainer, tint: Color) -> ProgressBar:
	var meter := ProgressBar.new()
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter.custom_minimum_size.y = 9
	meter.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = tint
	meter.add_theme_stylebox_override("fill",fill)
	row.add_child(meter)
	return meter

func _nearest_creature() -> int:
	var nearest := -1
	var distance := 3.0
	for i in range(creatures.size()):
		if creatures[i].bonded:
			continue
		var gap := player.position.distance_to(creatures[i].position)
		if gap < distance:
			distance = gap
			nearest = i
	return nearest

func _interact() -> void:
	var near := _nearest_creature()
	if near >= 0:
		var creature: Node3D = creatures[near]
		if near == 0 and not roster.has(0):
			if berries == 0:
				note = "Filizik bir meyve bekliyor. Yeşil çalılardan E ile topla."
				return
			berries -= 1
			creature.trust += 1
			if creature.trust >= 2:
				_bond(near)
			else:
				note = "Filizik yaklaşmana izin verdi. Bir meyve daha sun."
		elif creature.tired:
			_bond(near)
		elif roster.is_empty():
			note = "Önce Filizik ile arkadaş ol."
		else:
			_begin_training(near)
		_checkpoint_creatures()
		return
	for shrub in bushes:
		if player.position.distance_to(shrub.position) < 2.5:
			if berries < 12:
				berries = mini(12,berries+3)
				note = "Üç meyve topladın."
				_checkpoint_creatures()
			else:
				note = "Meyve kesen dolu."
			return
	note = "Kulaklı dostlara yaklaş · E tanış · Tab yoldaş değiştir"

func _begin_training(index: int) -> void:
	if index == active_species or roster.is_empty():
		return
	if battle >= 0:
		return
	battle = index
	var ally: Node3D = creatures[active_species]
	var rival: Node3D = creatures[index]
	ally_origin = ally.position
	ally.position = rival.position + Vector3(-3.2,0,1.2)
	ally.position.y = height_at(ally.position.x,ally.position.z)
	for actor in [ally,rival]:
		actor.engaged = true
		actor.walking = false
		actor.show()
		actor.label.hide()
	ally.look_at(Vector3(rival.position.x,ally.position.y,rival.position.z),Vector3.UP,true)
	rival.look_at(Vector3(ally.position.x,rival.position.y,ally.position.z),Vector3.UP,true)
	battle_camera = Camera3D.new()
	add_child(battle_camera)
	var middle := (ally.position+rival.position)*0.5
	battle_camera.position = middle + Vector3(1.3,2.1,5.0)
	battle_camera.look_at(middle + Vector3.UP*0.75)
	battle_camera.fov = 49
	battle_camera.current = true
	visuals.hide()
	friend_energy = 30+levels[active_species]*5
	rival_energy = 24+index*4
	turn_count = 0
	note = "Rakip mevzi aldı. Hamleni seç."

func _spar_again() -> void:
	if roster.is_empty() or battle >= 0:
		return
	var target := -1
	var distance := 4.0
	for i in range(3):
		if i == active_species:
			continue
		var gap := player.position.distance_to(creatures[i].position)
		if gap < distance:
			distance = gap
			target = i
	if target >= 0:
		_begin_training(target)
	else:
		note = "Karşılaşma için başka bir türe yaklaş."

func _bond(index: int) -> void:
	if roster.has(index):
		return
	roster.append(index)
	creatures[index].bonded = true
	creatures[index].hide()
	active_species = index
	note = COMPANION.SPECIES[index].name+" ekibine katıldı!"
	_checkpoint_creatures()

func _finish_encounter() -> void:
	if battle < 0:
		return
	var ally: Node3D = creatures[active_species]
	for actor in [ally,creatures[battle]]:
		actor.engaged = false
		actor.visible = not actor.bonded
		actor.label.show()
	ally.position = ally_origin
	battle = -1
	resolving = false
	visuals.show()
	camera_pivot.get_node("Camera").current = true
	battle_camera.queue_free()
	combat_card.hide()

func _strike(actor: Node3D, defender: Node3D) -> void:
	var start := actor.position
	var travel := defender.position - start
	travel.y = 0.0
	var motion := actor.create_tween()
	motion.tween_property(actor,"position",start-travel.normalized()*0.24,0.13)
	var contact := start+travel.normalized()*maxf(0.1,travel.length()-0.95)
	if actor.species == 2:
		motion.tween_property(actor,"position",start+Vector3.UP*0.72,0.19)
	motion.tween_property(actor,"position",contact,0.18)
	motion.tween_callback(_impact.bind(actor,defender))
	motion.tween_property(actor,"position",start,0.23)
	await motion.finished

func _impact(actor: Node3D, defender: Node3D) -> void:
	var center := defender.position + Vector3.UP*0.65
	var direction := (defender.position-actor.position).normalized()
	var tint: Color = COMPANION.SPECIES[actor.species].accent
	for i in range(5):
		var angle := TAU*i/5.0
		var burst := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radial_segments = 8
		sphere.rings = 3
		burst.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = tint
		burst.material_override = mat
		burst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(burst)
		burst.position = center
		var spread := Vector3(cos(angle),sin(angle),0.1)
		match actor.species:
			0:
				burst.scale = Vector3(0.40,0.065,0.12)
				burst.rotation.z = angle
			1:
				burst.scale = Vector3(0.16,0.24,0.16)
			2:
				burst.scale = Vector3(0.20,0.14,0.19)
		var flash := burst.create_tween()
		flash.set_parallel(true)
		flash.tween_property(burst,"position",center+spread*0.85+direction*0.45,0.25)
		flash.tween_property(burst,"scale",Vector3.ONE*0.015,0.25)
		flash.chain().tween_callback(burst.queue_free)
	var recoil := defender.create_tween()
	var initial: float = defender.visual.rotation.y
	recoil.tween_property(defender.visual,"rotation:y",initial+0.24,0.06)
	recoil.tween_property(defender.visual,"rotation:y",initial,0.15)

func _battle_action(guard: bool) -> void:
	if battle < 0 or resolving:
		return
	resolving = true
	var target := battle
	var ally: Node3D = creatures[active_species]
	var rival: Node3D = creatures[target]
	turn_count += 1
	var heavy := turn_count % 3 == 0
	if guard:
		friend_energy = mini(30+levels[active_species]*5,friend_energy+3)
		note = "Savunma alındı."
	else:
		note = COMPANION.SPECIES[active_species].move
		await _strike(ally,rival)
		rival_energy -= int(COMPANION.SPECIES[active_species].power)+levels[active_species]*2
	if rival_energy <= 0:
		creatures[target].tired = true
		experience[active_species] += 12
		# The starter shares field experience, even when another partner is active.
		if active_species != 0 and roster.has(0) and levels[0]<2:
			levels[0] = 2
		while levels[active_species]<99 and experience[active_species] >= levels[active_species]*10:
			experience[active_species] -= levels[active_species]*10
			levels[active_species] += 1
		note = "Karşılaşma kazanıldı. "+COMPANION.SPECIES[active_species].name+" seviye "+str(levels[active_species])+". E ile yeni dostuna yaklaş."
		_finish_encounter()
		_checkpoint_creatures()
		return
	note = "Rakip ağır vuruşa geçti." if heavy else "Rakip karşılık veriyor."
	await _strike(rival,ally)
	var incoming := 7+target
	if heavy:
		incoming *= 2
	friend_energy -= 1 if guard else incoming
	if heavy and guard:
		rival_energy = maxi(1,rival_energy-5)
	resolving = false
	note = "Hamleni seç."
	if friend_energy <= 0:
		note = "Gücün tükendi. Karşılaşmadan çekildin."
		_finish_encounter()

func _open_path() -> bool:
	if gate_open or player.position.distance_to(Vector3(0,height_at(0,-33),-33)) > 7:
		return false
	if not roster.has(0) or levels[0] < 2:
		note = "Sarmaşıklar için seviye 2 Filizik gerekli. Bir dostça antrenman yap."
		return false
	gate_open = true
	_apply_gate()
	note = "Filizik sarmaşıkları araladı! Yeni açıklığı keşfet."
	_checkpoint_creatures()
	return true

func _apply_gate() -> void:
	gate.visible = not gate_open
	gate.get_child(0).set_deferred("disabled",gate_open)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				if resolving:
					return
				_finish_encounter()
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_E:
				if battle < 0:
					_interact()
			KEY_R:
				_spar_again()
			KEY_F:
				if battle < 0:
					_open_path()
			KEY_1:
				_battle_action(false)
			KEY_2:
				_battle_action(true)
			KEY_TAB:
				if battle < 0 and not roster.is_empty():
					active_species = roster[(roster.find(active_species)+1)%roster.size()]
					_checkpoint_creatures()
			KEY_F11:
				var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x*0.003
		pitch = clampf(pitch-event.relative.y*0.003,-0.65,0.20)
		camera_pivot.rotation = Vector3(pitch,yaw,0)
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var input_vector := Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))).normalized()
	if battle >= 0:
		input_vector = Vector2.ZERO
	var direction := Basis(Vector3.UP,yaw)*Vector3(input_vector.x,0,input_vector.y)
	var sprint := Input.is_physical_key_pressed(KEY_SHIFT) and direction.length()>0.1
	player.velocity.x = direction.x*(RUN_SPEED if sprint else WALK_SPEED)
	player.velocity.z = direction.z*(RUN_SPEED if sprint else WALK_SPEED)
	if not player.is_on_floor():
		player.velocity.y -= GRAVITY*delta
	elif Input.is_physical_key_pressed(KEY_SPACE) and battle < 0 and jump_phase.is_empty():
		_begin_jump()
	elif jump_phase != "air":
		player.velocity.y = -0.2
	_advance_jump(delta)
	player.move_and_slide()
	player.position.x = clampf(player.position.x,-57,57)
	player.position.z = clampf(player.position.z,-57,57)
	if player.position.y < height_at(player.position.x,player.position.z)-3:
		player.position.y = height_at(player.position.x,player.position.z)+0.2
		player.velocity = Vector3.ZERO
	if direction.length()>0.01:
		visuals.rotation.y = lerp_angle(visuals.rotation.y,atan2(direction.x,direction.z),delta*10)
	_update_character_animation(delta,input_vector.length()>0.01,sprint)
	camera_pivot.position = camera_pivot.position.lerp(player.position+Vector3(0,1.5,0),minf(1,delta*8))
	var camera: Camera3D = camera_pivot.get_node("Camera")
	var end := camera_pivot.to_global(Vector3(0,1,camera_distance))
	var ray := PhysicsRayQueryParameters3D.create(camera_pivot.position,end)
	ray.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	camera.position = Vector3(0,1,camera_distance)
	if not hit.is_empty():
		camera.position = camera.position.normalized()*maxf(0.2,camera_pivot.position.distance_to(hit.position)-0.2)
	for creature in creatures:
		if creature.engaged or creature.bonded:
			continue
		creature.patrol(delta,player.position)
		creature.position.y = height_at(creature.position.x,creature.position.z)
	if gate_open and player.position.z < -38 and not discovered:
		discovered = true
		note = "Çiçekli açıklık keşfedildi. İlk yolculuğun tamamlandı!"
		_checkpoint_creatures()
	_refresh_interface()
	save_timer += delta
	if save_timer > 20:
		save_timer = 0
		_checkpoint_creatures()

func _refresh_interface() -> void:
	field_card.visible = battle < 0
	var goal := "Filizik ile dost ol · E ile meyve sun"
	if roster.has(0):
		goal = "Filizik ile bir saha karşılaşması kazan" if levels[0]<2 else "Sarmaşık kapıya git · F ile Filizik'e yardım et"
	if discovered:
		goal = "Çiçekli açıklık keşfedildi!"
	journal.text = "FİLİZYA · YOLDAŞLAR VADİSİ\n"+goal
	var team := "Ekibin henüz boş"
	if not roster.is_empty():
		team = "Yoldaş · "+COMPANION.SPECIES[active_species].name+"  Sv."+str(levels[active_species])+"  Deneyim "+str(experience[active_species])+"/"+str(levels[active_species]*10)
	panel.text = team+"\nMeyve "+str(berries)+"  ·  FPS "+str(Engine.get_frames_per_second())+"\nWASD hareket · Shift koş · Space zıpla · Tab yoldaş · E tanış · R karşılaşma · F yardım\n"+note
	if battle >= 0:
		prompt.text = ""
		combat_card.show()
		ally_meter.max_value = 30+levels[active_species]*5
		ally_meter.value = friend_energy
		foe_meter.max_value = 24+battle*4
		foe_meter.value = maxi(0,rival_energy)
		var shown_turn := turn_count if resolving else turn_count+1
		var threat := "AĞIR VURUŞ" if shown_turn%3 == 0 else "Saldırı"
		combat_text.text = "%s  %d   /   %s  %d\nRakibin niyeti · %s\n[1] %s     [2] Savun     [Esc] Çekil" % [COMPANION.SPECIES[active_species].name,friend_energy,COMPANION.SPECIES[battle].name,maxi(0,rival_energy),threat,COMPANION.SPECIES[active_species].move]
	else:
		prompt.text = "[E] "+COMPANION.SPECIES[_nearest_creature()].name+" ile tanış" if _nearest_creature()>=0 else ""

func _checkpoint_creatures() -> void:
	if not progress_writable or get_tree().current_scene != self:
		return
	var data := {"version":1,"berries":berries,"roster":roster,"levels":levels,"xp":experience,"trust":creatures[0].trust,"tired":[creatures[0].tired,creatures[1].tired,creatures[2].tired],"active":active_species,"gate":gate_open,"discovered":discovered,"position":[player.position.x,player.position.y,player.position.z]}
	var file := FileAccess.open(STATE_PATH+".tmp",FileAccess.WRITE)
	if file == null:
		note = "Kayıt dosyası yazılamadı."
		return
	file.store_string(JSON.stringify(data))
	file.flush()
	var ok := file.get_error()==OK
	file.close()
	if ok:
		DirAccess.rename_absolute(STATE_PATH+".tmp",STATE_PATH)

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func _load_progress() -> void:
	# Application names select a new user directory. Copy the existing adventure once.
	if not FileAccess.file_exists(STATE_PATH):
		var previous_folder := OS.get_user_data_dir().get_base_dir().path_join("Ashvale - Survival RPG Prototype")
		var previous_save := previous_folder.path_join("ashvale-companions-v1.json")
		if FileAccess.file_exists(previous_save):
			var migrated := DirAccess.copy_absolute(previous_save, ProjectSettings.globalize_path(STATE_PATH))
			if migrated != OK:
				progress_writable = false
				note = "Önceki kayıt aktarılamadı."
				return
	if not FileAccess.file_exists(STATE_PATH):
		return
	progress_writable = false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(STATE_PATH))
	if not data is Dictionary or data.get("version")!=1:
		note = "Kayıt okunamadı. Önceki kayıt korunuyor."
		return
	for key in ["levels","xp","tired","position"]:
		if not data.get(key) is Array or data[key].size()!=3:
			return
	if not data.get("roster") is Array:
		return
	for i in range(3):
		if not _number(data.levels[i]) or data.levels[i]<1 or data.levels[i]>99 or not _number(data.xp[i]) or data.xp[i]<0 or not data.tired[i] is bool:
			return
	for i in data.roster:
		if not _number(i) or i != int(i) or int(i) not in [0,1,2]:
			return
	for value in data.position:
		if not _number(value):
			return
	for key in ["berries","trust","active"]:
		if not _number(data.get(key)):
			return
	if not data.get("gate") is bool or not data.get("discovered") is bool:
		return
	progress_writable = true
	berries = clampi(int(data.berries),0,12)
	creatures[0].trust = clampi(int(data.trust),0,2)
	for i in range(3):
		levels[i]=int(data.levels[i])
		experience[i]=int(data.xp[i])
		creatures[i].tired = data.tired[i]
		if (data.roster.has(float(i)) or data.roster.has(i)) and not roster.has(i):
			roster.append(i)
			creatures[i].bonded = true
			creatures[i].hide()
	active_species = int(data.active) if roster.has(int(data.active)) else (roster[0] if not roster.is_empty() else 0)
	gate_open = data.gate
	discovered = data.discovered
	_apply_gate()
	player.position = Vector3(clampf(data.position[0],-57,57),data.position[1],clampf(data.position[2],-57,57))
	player.position.y = maxf(player.position.y,height_at(player.position.x,player.position.z)+0.1)
	note = "Yoldaşlarınla yolculuğa devam."

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if player != null and creatures.size()==3:
			_checkpoint_creatures()
