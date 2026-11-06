extends Node3D

# Elde tasinan mesale: sap, sarili bez, alev/kivilcim parcaciklari ve
# titreyen golgeli isik. Orijin = elin kavradigi nokta, +Y alev yonu.

var light: OmniLight3D
var _noise := FastNoiseLite.new()
var _time := 0.0

func _ready() -> void:
	_noise.frequency = 3.0
	var stick := MeshInstance3D.new()
	stick.name = "Stick"
	var cylinder := CylinderMesh.new()
	cylinder.radial_segments = 8
	cylinder.top_radius = 0.022
	cylinder.bottom_radius = 0.018
	cylinder.height = 0.55
	stick.mesh = cylinder
	stick.position.y = 0.12
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("#5a3a22")
	wood.roughness = 0.9
	stick.material_override = wood
	add_child(stick)
	var cloth_wrap := MeshInstance3D.new()
	cloth_wrap.name = "Wrap"
	var cloth := CylinderMesh.new()
	cloth.radial_segments = 8
	cloth.top_radius = 0.04
	cloth.bottom_radius = 0.032
	cloth.height = 0.12
	cloth_wrap.mesh = cloth
	cloth_wrap.position.y = 0.4
	var cloth_mat := StandardMaterial3D.new()
	cloth_mat.albedo_color = Color("#3a2b20")
	cloth_mat.emission_enabled = true
	cloth_mat.emission = Color(1.0, 0.35, 0.08)
	cloth_mat.emission_energy_multiplier = 1.2
	cloth_wrap.material_override = cloth_mat
	add_child(cloth_wrap)

	var flame := GPUParticles3D.new()
	flame.name = "Flame"
	flame.amount = 24
	flame.lifetime = 0.5
	flame.local_coords = false
	flame.position.y = 0.47
	flame.visibility_aabb = AABB(Vector3(-1, -1, -1), Vector3(2, 3, 2))
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var quad := QuadMesh.new()
	quad.size = Vector2(0.14, 0.14)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = preload("res://scripts/campfire.gd")._soft_dot()
	quad.material = mat
	flame.draw_pass_1 = quad
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.035
	process.direction = Vector3.UP
	process.spread = 10.0
	process.initial_velocity_min = 0.35
	process.initial_velocity_max = 0.7
	process.gravity = Vector3(0, 0.5, 0)
	var colors := Gradient.new()
	colors.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	colors.colors = PackedColorArray([Color(1.0, 0.85, 0.45, 0.0), Color(1.0, 0.55, 0.12, 0.9), Color(0.6, 0.1, 0.02, 0.0)])
	var ramp := GradientTexture1D.new()
	ramp.gradient = colors
	process.color_ramp = ramp
	flame.process_material = process
	add_child(flame)

	light = OmniLight3D.new()
	light.name = "TorchLight"
	light.position = Vector3(0, 0.55, 0)
	light.light_color = Color(1.0, 0.6, 0.28)
	light.light_energy = 1.6
	light.omni_range = 9.0
	light.omni_attenuation = 1.3
	light.shadow_enabled = true
	light.light_volumetric_fog_energy = 0.6
	add_child(light)

func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	light.light_energy = 1.6 + _noise.get_noise_1d(_time * 9.0) * 0.45
