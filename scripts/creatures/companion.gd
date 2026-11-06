extends Node3D

const SPECIES := [
	{"name": "Filizik", "color": Color("#78bb79"), "accent": Color("#c7ed88"), "move": "Yaprak Kesiği", "power": 7},
	{"name": "Damlup", "color": Color("#6ec9df"), "accent": Color("#c4eff6"), "move": "Basınç Dalgası", "power": 6},
	{"name": "Çakılcık", "color": Color("#c99385"), "accent": Color("#f4d394"), "move": "Fay Darbesi", "power": 8},
]
const ELEMENT := ["Doğa", "Su", "Taş"]
const SPECIAL := ["Kök Kapanı", "Akıntı Mızrağı", "Kaya Çöküşü"]
const BASE_HP := [28, 26, 32]
const SPECIAL_LEVEL := 2

static func max_hp(index: int, level: int) -> int:
	return BASE_HP[index] + level * 5

static func potency(attacker: int, defender: int) -> float:
	if attacker == defender:
		return 1.0
	return 1.5 if (attacker + 1) % ELEMENT.size() == defender else 0.7

static func damage(attacker: int, level: int, defender: int, special: bool) -> int:
	var power := int(SPECIES[attacker].power) + level * 2 + (5 if special else 0)
	return maxi(1,roundi(power * potency(attacker,defender)))

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
var tail: MeshInstance3D
var fin_rest: Array[float] = []
var label: Label3D
var shared_materials := {}

func _ready() -> void:
	den = position
	destination = den
	phase = species * 1.73
	visual = Node3D.new()
	add_child(visual)
	var info: Dictionary = SPECIES[species]
	match species:
		0: _forest_stalker()
		1: _river_glider()
		2: _stoneback()
	for fin in ears:
		fin_rest.append(fin.rotation.z)
	label = Label3D.new()
	label.text = info.name
	label.position.y = 1.95
	label.font_size = 34
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#fff1cb")
	label.outline_size = 7
	add_child(label)

# Elliptical sections follow the animal's spine from tail to nose.
# Each row contains forward distance, height, half width and half depth.
func _form(rows: Array, tint: Color) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 12
	for k in range(rows.size()-1):
		for j in range(sides):
			var a := _rim(rows[k], j, sides)
			var b := _rim(rows[k], j+1, sides)
			var c := _rim(rows[k+1], j, sides)
			var d := _rim(rows[k+1], j+1, sides)
			for pt in [a,c,b,b,c,d]:
				surface.add_vertex(pt)
	surface.generate_normals()
	surface.index()
	var part := MeshInstance3D.new()
	part.mesh = surface.commit()
	part.material_override = _paint(tint)
	visual.add_child(part)
	return part

func _rim(row: Vector4, j: int, n: int) -> Vector3:
	var a := TAU*j/n
	return Vector3(cos(a)*row.z,row.y+sin(a)*row.w,row.x)

# A folded, tapered blade serves as an ear, fin or mineral plate.
func _blade(origin: Vector3, tip: Vector3, span: Vector3, tint: Color) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mid := tip*0.45
	var edge := mid+Vector3(0,0,0.065)
	for pt in [Vector3.ZERO,mid-span,edge,Vector3.ZERO,edge,mid+span,mid-span,tip,edge,edge,tip,mid+span]:
		surface.add_vertex(pt)
	surface.generate_normals()
	var part := MeshInstance3D.new()
	part.mesh = surface.commit()
	part.position = origin
	part.material_override = _paint(tint)
	visual.add_child(part)
	return part

func _eye(x: float, y: float, z: float, size_factor: float, side: float) -> void:
	var eye := _blob(Vector3(x,y,z),Vector3(0.096,0.054,0.055)*size_factor,Color("#23323a"))
	eye.rotation.z = side*0.16
	_blob(Vector3(x,y,z+0.040*size_factor),Vector3(0.045,0.045,0.018)*size_factor,Color("#e7bc65"))
	_blob(Vector3(x,y,z+0.056*size_factor),Vector3(0.015,0.038,0.009)*size_factor,Color("#21303d"))

func _forest_stalker() -> void:
	var fern := Color("#45896b")
	var moss := Color("#8ebc71")
	_form([Vector4(-0.59,0.68,0.04,0.06),Vector4(-0.42,0.7,0.32,0.36),Vector4(0,0.82,0.26,0.29),Vector4(0.35,0.94,0.31,0.36),Vector4(0.5,1.02,0.18,0.23)],fern)
	_form([Vector4(0.23,1.22,0.13,0.16),Vector4(0.44,1.25,0.31,0.29),Vector4(0.64,1.20,0.26,0.19),Vector4(0.86,1.14,0.11,0.09),Vector4(0.91,1.15,0.04,0.05)],moss)
	tail = _blade(Vector3(0,0.68,-0.46),Vector3(-0.22,0.45,-0.87),Vector3(0.19,0,0),moss)
	for side in [-1.0,1.0]:
		ears.append(_blade(Vector3(side*0.21,1.39,0.41),Vector3(side*0.26,0.54,-0.08),Vector3(0.14,0,0),fern))
		_blade(Vector3(side*0.26,1.20,0.45),Vector3(side*0.29,-0.26,-0.20),Vector3(0,0.13,0),moss)
		_eye(side*0.19,1.26,0.68,0.88,side)
		for z in [-0.34,0.32]:
			_blob(Vector3(side*0.225,0.49,z),Vector3(0.13,0.25,0.15),fern)
			feet.append(_blob(Vector3(side*0.23,0.21,z+0.035),Vector3(0.091,0.21,0.113),Color("#365e54")))
	_blob(Vector3(0,1.15,0.90),Vector3(0.082,0.042,0.041),Color("#344545"))

func _river_glider() -> void:
	var teal := Color("#34879a")
	var pearl := Color("#adddd6")
	_form([Vector4(-0.90,0.46,0.06,0.07),Vector4(-0.56,0.5,0.19,0.18),Vector4(0.0,0.53,0.36,0.27),Vector4(0.47,0.58,0.43,0.24),Vector4(0.78,0.55,0.28,0.16),Vector4(0.91,0.54,0.06,0.055)],teal)
	tail = _blade(Vector3(0,0.48,-0.78),Vector3(0,0.14,-0.92),Vector3(0.35,0,0),pearl)
	for side in [-1.0,1.0]:
		ears.append(_blade(Vector3(side*0.29,0.58,0.08),Vector3(side*0.87,0.10,-0.44),Vector3(0,0.08,0.29),pearl))
		_blade(Vector3(side*0.33,0.62,0.36),Vector3(side*0.37,0.15,-0.08),Vector3(0,0.07,0.06),Color("#df886e"))
		_eye(side*0.255,0.68,0.72,0.83,side)
		feet.append(_blob(Vector3(side*0.24,0.24,-0.31),Vector3(0.15,0.075,0.28),teal))
	_blade(Vector3(0,0.74,-0.22),Vector3(0,0.42,-0.37),Vector3(0,0,0.23),Color("#75c7bc"))

func _stoneback() -> void:
	var slate := Color("#596571")
	var amber := Color("#cf935b")
	_form([Vector4(-0.80,0.58,0.12,0.14),Vector4(-0.50,0.65,0.47,0.35),Vector4(0,0.68,0.51,0.39),Vector4(0.47,0.61,0.41,0.32),Vector4(0.77,0.54,0.27,0.22),Vector4(0.97,0.48,0.12,0.09)],slate)
	for i in range(3):
		var z := -0.57 + i*0.29
		_form([Vector4(z-0.18,0.77,0.39,0.15),Vector4(z,0.81,0.51,0.37),Vector4(z+0.16,0.78,0.43,0.21)],Color("#8b8390") if i%2==0 else Color("#706e80"))
	tail = _blade(Vector3(0,0.59,-0.66),Vector3(0,-0.17,-0.60),Vector3(0.17,0,0),slate)
	for side in [-1.0,1.0]:
		ears.append(_blade(Vector3(side*0.25,0.68,0.56),Vector3(side*0.18,0.34,0.25),Vector3(0.11,0,0),amber))
		_eye(side*0.20,0.61,0.83,0.85,side)
		for z in [-0.47,0.38]:
			feet.append(_blob(Vector3(side*0.36,0.23,z),Vector3(0.155,0.22,0.195),slate))
			_blob(Vector3(side*0.36,0.11,z+0.13),Vector3(0.14,0.075,0.17),amber)

func _paint(color: Color) -> ShaderMaterial:
	if not shared_materials.has(color):
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://assets/shaders/camp_ink.gdshader")
		mat.set_shader_parameter("paint",color)
		mat.set_shader_parameter("ink_width",0.065)
		shared_materials[color] = mat
	return shared_materials[color]

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
	part.material_override = _paint(color)
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
	if not visible:
		return
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
		var gait := 1.0 if i in [0,3] else -1.0
		feet[i].rotation.x = stride*gait*(0.62 if walking else 0.035)
	for i in range(ears.size()):
		var side := -1.0 if i==0 else 1.0
		ears[i].rotation.z = fin_rest[i]+side*(0.10*stride if walking else 0.025*sin(phase*2))
	if tail != null:
		tail.rotation.y = sin(phase*(4.2 if walking else 1.5))*(0.32 if species==1 else 0.16)
	label.text = SPECIES[species].name
