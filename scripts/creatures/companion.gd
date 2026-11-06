extends Node3D

const SPECIES := [
	{"name": "Filizik", "color": Color("#78bb79"), "accent": Color("#c7ed88"), "move": "Yaprak Pıtırtısı", "power": 7},
	{"name": "Damlup", "color": Color("#6ec9df"), "accent": Color("#c4eff6"), "move": "Su Halkası", "power": 6},
	{"name": "Çakılcık", "color": Color("#c99385"), "accent": Color("#f4d394"), "move": "Çakıl Taklası", "power": 8},
]
var species := 0
var bonded := false
var tired := false
var trust := 0
var visual: Node3D
var phase := 0.0
var den := Vector3.ZERO
var destination := Vector3.ZERO
var rest_time := 0.0
var patrol_step := 0
var walking := false
var engaged := false
var feet: Array[MeshInstance3D] = []
var ears: Array[MeshInstance3D] = []
var label: Label3D
var shared_materials := {}

func _ready() -> void:
	den = position
	destination = den
	phase = species * 1.73
	visual = Node3D.new()
	add_child(visual)
	var info: Dictionary = SPECIES[species]
	_blob(Vector3(0,0.44,0), Vector3(0.48,0.43,0.39), info.color)
	_blob(Vector3(0,0.91,0.045), Vector3(0.48,0.38,0.37), info.color)
	for sign_value in [-1.0,1.0]:
		feet.append(_blob(Vector3(sign_value*0.29,0.12,0.08),Vector3(0.20,0.12,0.26),info.accent))
		_blob(Vector3(sign_value*0.44,0.49,0.08),Vector3(0.12,0.20,0.14),info.accent)
		_blob(Vector3(sign_value*0.20,1.02,0.37),Vector3(0.095,0.128,0.036),Color("#213c52"))
		_blob(Vector3(sign_value*0.20-0.018,1.065,0.406),Vector3(0.029,0.036,0.014),Color.WHITE)
		_blob(Vector3(sign_value*0.32,0.86,0.345),Vector3(0.07,0.03,0.018),Color("#f5aa91"))
		var ear: MeshInstance3D
		if species == 0:
			ear = _blob(Vector3(sign_value*0.34,1.37,0),Vector3(0.16,0.40,0.09),info.accent)
		elif species == 1:
			ear = _blob(Vector3(sign_value*0.48,1.16,0),Vector3(0.31,0.14,0.09),info.accent)
		else:
			ear = _blob(Vector3(sign_value*0.28,1.34,0),Vector3(0.18,0.24,0.16),info.accent)
		ear.rotation.z = sign_value * -0.48
		ears.append(ear)
	_blob(Vector3(0,0.86,0.405),Vector3(0.06,0.025,0.022),Color("#4c4b5f"))
	if species == 0:
		for i in range(2):
			var leaf := _blob(Vector3(-0.24+i*0.45,0.70,-0.36),Vector3(0.32,0.09,0.49),Color("#44975b"))
			leaf.rotation.z = -0.35+i*0.7
	elif species == 1:
		_blob(Vector3(0,1.37,-0.04),Vector3(0.17,0.28,0.16),info.accent)
	else:
		_blob(Vector3(0,0.62,-0.30),Vector3(0.51,0.37,0.25),Color("#958b9c"))
	label = Label3D.new()
	label.text = info.name
	label.position.y = 1.95
	label.font_size = 34
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#fff1cb")
	label.outline_size = 7
	add_child(label)

func _blob(center: Vector3, shape_scale: Vector3, color: Color) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radial_segments = 12
	shape.rings = 6
	shape.radius = 1
	shape.height = 2
	var part := MeshInstance3D.new()
	part.mesh = shape
	part.position = center
	part.scale = shape_scale
	if not shared_materials.has(color):
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://assets/shaders/camp_ink.gdshader")
		mat.set_shader_parameter("paint",color)
		mat.set_shader_parameter("ink_width",0.085)
		shared_materials[color] = mat
	part.material_override = shared_materials[color]
	visual.add_child(part)
	return part

func patrol(delta: float, observer: Vector3) -> void:
	walking = false
	if bonded or tired or engaged:
		return
	if position.distance_to(observer) < 3.0:
		var bearing := observer - position
		if bearing.length_squared() > 0.02:
			rotation.y = lerp_angle(rotation.y, atan2(bearing.x,bearing.z), minf(delta*5,1))
		return
	if rest_time > 0:
		rest_time -= delta
		return
	var step := destination - position
	step.y = 0
	if step.length() < 0.12:
		patrol_step += 1
		var bearing := patrol_step * 2.40 + species
		destination = den + Vector3(cos(bearing)*2.7,0,sin(bearing)*1.7)
		rest_time = 0.8 + species * 0.4
	else:
		walking = true
		var direction := step.normalized()
		position += direction * minf(step.length(),delta*(1.25-0.2*species))
		rotation.y = lerp_angle(rotation.y,atan2(direction.x,direction.z),minf(delta*5,1))

func _process(delta: float) -> void:
	phase += delta
	var stride := sin(phase*(8.5-species))
	var lift := 0.03
	if walking:
		lift = [0.22,0.08,0.045][species]
	visual.position.y = absf(stride)*lift
	visual.rotation.z = stride*(0.09 if walking else 0.022)
	visual.rotation.x = -0.14 if engaged else 0.0
	visual.scale.y = 0.84 if tired and not engaged else 1.0
	for i in range(feet.size()):
		var side := -1.0 if i == 0 else 1.0
		feet[i].rotation.x = stride*side*(0.65 if walking else 0.05)
		ears[i].rotation.z = side*(0.48 + 0.12*stride if walking else 0.48 + 0.035*sin(phase*2))
	label.text = SPECIES[species].name
