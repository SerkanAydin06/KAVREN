extends Node3D

# Kamp atesi: tas halka, capraz kutukler, alev/duman/kivilcim parcaciklari
# ve titreyen golgeli isik. Gece cevreyi aydinlatan ana isik kaynagi.

const STONE := Color("#6f706b")
const LOG := Color("#3d2a1c")
const CHAR := Color("#1d1512")

const WOOD_SECONDS := 75.0
const MAX_FUEL := WOOD_SECONDS * 4
var fuel := WOOD_SECONDS * 2

func set_fuel(seconds: float) -> void:
	fuel = clampf(seconds, 0, MAX_FUEL)
	if light != null and light.visible != (fuel > 0):
		light.visible = fuel > 0
		for child in get_children():
			if child is GPUParticles3D:
				child.emitting = light.visible
				child.visible = light.visible

var light: OmniLight3D
var _flicker := FastNoiseLite.new()
var _time := 0.0

func _ready() -> void:
	_flicker.frequency = 2.2
	_build_ring()
	_build_logs()
	_build_particles()
	light = OmniLight3D.new()
	light.name = "FireLight"
	light.position = Vector3(0, 0.75, 0)
	light.light_color = Color(1.0, 0.56, 0.22)
	light.light_energy = 2.6
	light.omni_range = 11.0
	light.omni_attenuation = 1.4
	light.shadow_enabled = true
	light.shadow_blur = 1.5
	light.light_volumetric_fog_energy = 0.8
	add_child(light)

func _process(delta: float) -> void:
	if fuel <= 0:
		return
	set_fuel(fuel - delta)
	_time += delta
	var n := _flicker.get_noise_1d(_time * 10.0)
	light.light_energy = 2.6 + n * 0.9
	light.position = Vector3(n * 0.05, 0.75 + n * 0.04, _flicker.get_noise_1d(_time * 7.0 + 30.0) * 0.05)

func _material(color: Color, roughness := 0.9) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat

func _build_ring() -> void:
	var stone_mat := _material(STONE)
	for i in range(10):
		var angle := float(i) * TAU / 10.0
		var stone := MeshInstance3D.new()
		stone.name = "RingStone_%d" % i
		var shape := SphereMesh.new()
		shape.radial_segments = 7
		shape.rings = 4
		shape.radius = 0.2
		shape.height = 0.26
		stone.mesh = shape
		stone.material_override = stone_mat
		stone.position = Vector3(cos(angle) * 0.82, 0.08, sin(angle) * 0.82)
		stone.rotation = Vector3(0.3 * i, angle, 0.2)
		stone.scale = Vector3(1.0 + 0.15 * (i % 3), 0.8, 0.9)
		add_child(stone)
	var ash := MeshInstance3D.new()
	ash.name = "Ash"
	var disc := CylinderMesh.new()
	disc.top_radius = 0.72
	disc.bottom_radius = 0.75
	disc.height = 0.03
	ash.mesh = disc
	ash.position.y = 0.015
	ash.material_override = _material(CHAR)
	add_child(ash)

func _build_logs() -> void:
	var log_mat := _material(LOG)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(0.2, 0.07, 0.03)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.35, 0.08)
	glow.emission_energy_multiplier = 2.5
	for i in range(4):
		var angle := float(i) * TAU / 4.0 + 0.4
		var firewood := MeshInstance3D.new()
		firewood.name = "Log_%d" % i
		var cylinder := CylinderMesh.new()
		cylinder.radial_segments = 8
		cylinder.top_radius = 0.07
		cylinder.bottom_radius = 0.09
		cylinder.height = 0.95
		firewood.mesh = cylinder
		firewood.material_override = log_mat
		# Kutukler ortada birbirine dayanir (tipi atesi).
		firewood.position = Vector3(cos(angle) * 0.22, 0.28, sin(angle) * 0.22)
		firewood.rotation = Vector3(0, -angle, 0)
		firewood.rotate_object_local(Vector3.FORWARD, deg_to_rad(52))
		add_child(firewood)
	var coals := MeshInstance3D.new()
	coals.name = "Coals"
	var bed := SphereMesh.new()
	bed.radius = 0.38
	bed.height = 0.16
	coals.mesh = bed
	coals.position.y = 0.05
	coals.material_override = glow
	add_child(coals)

func _particle_material(additive: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = _soft_dot()
	return mat

static var _dot_texture: ImageTexture
static func _soft_dot() -> ImageTexture:
	if _dot_texture != null:
		return _dot_texture
	var size := 64
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in range(size):
		for x in range(size):
			var d := Vector2(x - size * 0.5 + 0.5, y - size * 0.5 + 0.5).length() / (size * 0.5)
			var a := clampf(1.0 - d, 0.0, 1.0)
			image.set_pixel(x, y, Color(1, 1, 1, a * a))
	_dot_texture = ImageTexture.create_from_image(image)
	return _dot_texture

func _emitter(node_name: String, amount: int, lifetime: float, quad_size: float, color_ramp: Gradient, additive: bool) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = node_name
	particles.amount = amount
	particles.lifetime = lifetime
	particles.local_coords = false
	particles.visibility_aabb = AABB(Vector3(-2, -0.5, -2), Vector3(4, 6, 4))
	var quad := QuadMesh.new()
	quad.size = Vector2(quad_size, quad_size)
	quad.material = _particle_material(additive)
	particles.draw_pass_1 = quad
	var process := ParticleProcessMaterial.new()
	var ramp := GradientTexture1D.new()
	ramp.gradient = color_ramp
	process.color_ramp = ramp
	particles.process_material = process
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particles)
	return particles

func _build_particles() -> void:
	var flame_colors := Gradient.new()
	flame_colors.offsets = PackedFloat32Array([0.0, 0.25, 0.6, 1.0])
	flame_colors.colors = PackedColorArray([Color(1.0, 0.85, 0.45, 0.0), Color(1.0, 0.6, 0.15, 0.9), Color(0.9, 0.25, 0.05, 0.6), Color(0.3, 0.05, 0.02, 0.0)])
	var flames := _emitter("Flames", 46, 0.9, 0.42, flame_colors, true)
	flames.position.y = 0.15
	var flame_process := flames.process_material as ParticleProcessMaterial
	flame_process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	flame_process.emission_sphere_radius = 0.22
	flame_process.direction = Vector3.UP
	flame_process.spread = 12.0
	flame_process.initial_velocity_min = 0.5
	flame_process.initial_velocity_max = 1.1
	flame_process.gravity = Vector3(0, 0.6, 0)
	flame_process.scale_min = 0.6
	flame_process.scale_max = 1.2
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 0.7))
	shrink.add_point(Vector2(0.3, 1.0))
	shrink.add_point(Vector2(1.0, 0.1))
	var shrink_texture := CurveTexture.new()
	shrink_texture.curve = shrink
	flame_process.scale_curve = shrink_texture

	var smoke_colors := Gradient.new()
	smoke_colors.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	smoke_colors.colors = PackedColorArray([Color(0.3, 0.28, 0.27, 0.0), Color(0.32, 0.31, 0.3, 0.35), Color(0.5, 0.5, 0.5, 0.0)])
	var smoke := _emitter("Smoke", 28, 4.5, 0.9, smoke_colors, false)
	smoke.position.y = 0.9
	var smoke_process := smoke.process_material as ParticleProcessMaterial
	smoke_process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	smoke_process.emission_sphere_radius = 0.15
	smoke_process.direction = Vector3.UP
	smoke_process.spread = 15.0
	smoke_process.initial_velocity_min = 0.5
	smoke_process.initial_velocity_max = 0.8
	smoke_process.gravity = Vector3(0.25, 0.15, 0.08) # hafif ruzgar
	smoke_process.scale_min = 0.8
	smoke_process.scale_max = 1.4
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.4))
	grow.add_point(Vector2(1.0, 2.6))
	var grow_texture := CurveTexture.new()
	grow_texture.curve = grow
	smoke_process.scale_curve = grow_texture

	var ember_colors := Gradient.new()
	ember_colors.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
	ember_colors.colors = PackedColorArray([Color(1.0, 0.75, 0.3, 1.0), Color(1.0, 0.35, 0.05, 0.8), Color(0.5, 0.1, 0.0, 0.0)])
	var embers := _emitter("Embers", 22, 2.2, 0.05, ember_colors, true)
	embers.position.y = 0.4
	var ember_process := embers.process_material as ParticleProcessMaterial
	ember_process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	ember_process.emission_sphere_radius = 0.25
	ember_process.direction = Vector3.UP
	ember_process.spread = 25.0
	ember_process.initial_velocity_min = 1.0
	ember_process.initial_velocity_max = 2.4
	ember_process.gravity = Vector3(0.15, -0.2, 0.0)
	ember_process.turbulence_enabled = true
	ember_process.turbulence_noise_strength = 0.6
	ember_process.turbulence_noise_scale = 2.0
