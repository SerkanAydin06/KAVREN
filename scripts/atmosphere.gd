extends Node3D

# Ashvale atmosferi: prosedurel gokyuzu (bulut, gunes, yildiz), gun-gece
# dongusu, gunes/ay isigi, GI, SSAO, hacimsel sis ve ton esleme.
# Forward+ icin ayarlandi; Compatibility'de desteklenmeyen efektler sessizce yok sayilir.

signal hour_changed(hour: float)

@export var day_length_minutes := 10.0 # gercek dakikada bir tam gun
@export_range(0.0, 24.0, 0.25) var start_hour := 8.5
@export var time_flows := true

const SUN_MAX_ELEVATION := 62.0 # derece, ogle
const SUN_AZIMUTH_TILT := 25.0 # gunes yayi tam dogu-batidan biraz kayik
const SUNRISE_HOUR := 5.5
const SUNSET_HOUR := 19.5

const SKY_SHADER := """
shader_type sky;
render_mode use_debanding;

uniform vec3 day_top : source_color = vec3(0.20, 0.42, 0.78);
uniform vec3 day_horizon : source_color = vec3(0.70, 0.82, 0.92);
uniform vec3 sunset_horizon : source_color = vec3(1.0, 0.52, 0.26);
uniform vec3 sunset_top : source_color = vec3(0.30, 0.32, 0.55);
uniform vec3 night_top : source_color = vec3(0.008, 0.012, 0.035);
uniform vec3 night_horizon : source_color = vec3(0.03, 0.05, 0.09);
uniform vec3 ground_tint : source_color = vec3(0.24, 0.21, 0.16);
uniform sampler2D cloud_noise : filter_linear_mipmap, repeat_enable;
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.45;
uniform vec2 cloud_offset = vec2(0.0);
uniform float day_factor : hint_range(0.0, 1.0) = 1.0;
uniform float sunset_factor : hint_range(0.0, 1.0) = 0.0;
uniform vec3 sun_direction = vec3(0.0, 1.0, 0.0);
uniform vec3 moon_direction = vec3(0.0, -1.0, 0.0);

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float up = clamp(dir.y, 0.0, 1.0);
	vec3 flat_dir = normalize(vec3(dir.x, 0.0001, dir.z));
	vec3 flat_sun = normalize(vec3(sun_direction.x, 0.0001, sun_direction.z));
	float toward_sun = max(dot(flat_dir, flat_sun), 0.0);

	vec3 top = mix(night_top, day_top, day_factor);
	vec3 horizon = mix(night_horizon, day_horizon, day_factor);
	top = mix(top, sunset_top, sunset_factor * 0.55);
	horizon = mix(horizon, sunset_horizon, sunset_factor * (0.3 + 0.7 * pow(toward_sun, 2.0)));
	vec3 col = mix(horizon, top, pow(up, 0.5));

	// Ufkun altinda: zemin yansimasi (GI ve yansimalar icin).
	if (dir.y < 0.0) {
		vec3 below = ground_tint * (0.15 + 0.85 * day_factor);
		col = mix(horizon, below, smoothstep(0.0, 0.2, -dir.y));
	}

	// Gunes: keskin disk + genis hale.
	float sun_dot = dot(dir, normalize(sun_direction));
	float sun_visible = smoothstep(-0.08, 0.02, sun_direction.y);
	vec3 sun_tint = mix(vec3(1.0, 0.55, 0.25), vec3(1.0, 0.95, 0.85), clamp(sun_direction.y * 3.0, 0.0, 1.0));
	col += sun_tint * sun_visible * (smoothstep(0.9993, 0.9997, sun_dot) * 25.0 + pow(max(sun_dot, 0.0), 220.0) * 1.6 + pow(max(sun_dot, 0.0), 12.0) * 0.18 * (0.4 + sunset_factor));

	// Ay.
	float moon_dot = dot(dir, normalize(moon_direction));
	float moon_visible = smoothstep(-0.05, 0.05, moon_direction.y) * (1.0 - day_factor);
	col += vec3(0.85, 0.9, 1.0) * moon_visible * (smoothstep(0.9994, 0.9996, moon_dot) * 3.0 + pow(max(moon_dot, 0.0), 300.0) * 0.4);

	// Yildizlar: sadece gece, ufka yakin soner.
	if (!AT_CUBEMAP_PASS && dir.y > 0.0) {
		vec3 cell = floor(dir * 320.0);
		float star = step(0.9975, hash(cell));
		float twinkle = 0.6 + 0.4 * sin(TIME * 2.0 + hash(cell + 3.1) * 40.0);
		col += vec3(star * twinkle) * (1.0 - day_factor) * smoothstep(0.0, 0.25, dir.y) * 1.6;
	}

	// Bulutlar: gok kubbesi duzlemine izdusum, iki olcekli gurultu.
	if (dir.y > 0.0) {
		vec2 uv = dir.xz / (dir.y + 0.18) * 0.22;
		float n = texture(cloud_noise, uv + cloud_offset).r * 0.65 + texture(cloud_noise, uv * 2.7 - cloud_offset * 1.6).r * 0.35;
		float threshold = 1.0 - cloud_coverage;
		float density = smoothstep(threshold, threshold + 0.28, n) * smoothstep(0.0, 0.12, dir.y);
		float thickness = smoothstep(threshold, threshold + 0.6, n);
		vec3 lit = mix(vec3(1.0), vec3(1.0, 0.7, 0.5), sunset_factor);
		vec3 shade = mix(vec3(0.55, 0.6, 0.7), vec3(0.45, 0.35, 0.4), sunset_factor);
		vec3 cloud_col = mix(lit, shade, thickness) * mix(0.06, 1.0, day_factor);
		cloud_col += sun_tint * pow(max(sun_dot, 0.0), 8.0) * 0.35 * sun_visible * (1.0 - thickness);
		col = mix(col, cloud_col, density * 0.92);
	}
	COLOR = col;
}
"""

var hour := 8.5
var environment: Environment
var sky_material: ShaderMaterial
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var _cloud_offset := Vector2.ZERO
var _cloud_target := 0.45
var cloud_coverage := 0.45
var _cloud_timer := 0.0
var _weather_random := RandomNumberGenerator.new()

func _ready() -> void:
	hour = start_hour
	_weather_random.seed = 1105
	_build()
	apply_time()

func _build() -> void:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.008
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 5
	var noise_texture := NoiseTexture2D.new()
	noise_texture.width = 512
	noise_texture.height = 512
	noise_texture.seamless = true
	noise_texture.generate_mipmaps = true
	noise_texture.noise = noise

	var shader := Shader.new()
	shader.code = SKY_SHADER
	sky_material = ShaderMaterial.new()
	sky_material.shader = shader
	sky_material.set_shader_parameter("cloud_noise", noise_texture)

	var sky := Sky.new()
	sky.sky_material = sky_material
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL

	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_sky_contribution = 1.0
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	# Ton esleme: AgX dogal renk ve yumusak parlak alanlar.
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.tonemap_exposure = 1.0
	environment.tonemap_white = 6.0
	# Temas golgeleri ve dolayli isik.
	environment.ssao_enabled = true
	environment.ssao_radius = 1.4
	environment.ssao_intensity = 1.8
	environment.ssao_power = 1.6
	environment.ssao_detail = 0.6
	environment.ssao_light_affect = 0.15
	environment.ssil_enabled = true
	environment.ssil_radius = 4.0
	environment.ssil_intensity = 0.7
	environment.sdfgi_enabled = true
	environment.sdfgi_use_occlusion = true
	environment.sdfgi_cascades = 4
	environment.sdfgi_min_cell_size = 0.25
	environment.sdfgi_y_scale = Environment.SDFGI_Y_SCALE_75_PERCENT
	environment.sdfgi_energy = 0.9
	environment.sdfgi_bounce_feedback = 0.45
	# Parlama: ates ve gunes cevresi.
	environment.glow_enabled = true
	environment.glow_intensity = 0.55
	environment.glow_strength = 0.9
	environment.glow_bloom = 0.04
	environment.glow_hdr_threshold = 1.15
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	# Mesafe sisi (hava perspektifi) + hacimsel sis (isik huzmeleri).
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	environment.fog_density = 0.0035
	environment.fog_aerial_perspective = 0.55
	environment.fog_sky_affect = 0.25
	environment.fog_sun_scatter = 0.25
	environment.volumetric_fog_enabled = true
	environment.volumetric_fog_density = 0.012
	environment.volumetric_fog_albedo = Color(0.92, 0.94, 0.96)
	environment.volumetric_fog_anisotropy = 0.55
	environment.volumetric_fog_length = 80.0
	environment.volumetric_fog_ambient_inject = 0.25
	environment.volumetric_fog_sky_affect = 0.0
	# Hafif renk ayari.
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.08
	environment.adjustment_contrast = 1.04

	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	world.environment = environment
	add_child(world)

	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 110.0
	sun.directional_shadow_blend_splits = true
	sun.shadow_blur = 1.2
	sun.light_angular_distance = 0.6 # yumusak (PCSS) golge kenari
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 1.2
	sun.light_volumetric_fog_energy = 1.4
	sun.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	add_child(sun)

	moon = DirectionalLight3D.new()
	moon.name = "Moon"
	moon.light_color = Color(0.62, 0.72, 1.0)
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 60.0
	moon.shadow_blur = 2.0
	moon.light_volumetric_fog_energy = 0.6
	moon.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	add_child(moon)

func _process(delta: float) -> void:
	if time_flows and day_length_minutes > 0.0:
		var previous := hour
		hour = fposmod(hour + delta * 24.0 / (day_length_minutes * 60.0), 24.0)
		if int(previous) != int(hour):
			hour_changed.emit(hour)
	_update_weather(delta)
	apply_time()

func advance_hours(amount: float) -> void:
	hour = fposmod(hour + amount, 24.0)
	hour_changed.emit(hour)
	apply_time()

func set_hour(value: float) -> void:
	hour = fposmod(value, 24.0)
	apply_time()

func clock_text() -> String:
	var minutes := int(hour * 60.0) % (24 * 60)
	return "%02d:%02d" % [floori(minutes / 60.0), minutes % 60]

func is_night() -> bool:
	return sun_direction().y < -0.02

func sun_direction() -> Vector3:
	# Gun 05:30-19:30 (14 saat): dogu ufku -> tepe (SUN_MAX_ELEVATION) -> bati ufku.
	# Gece ayni yay ufkun altinda devam eder.
	var phase: float
	if hour >= SUNRISE_HOUR and hour <= SUNSET_HOUR:
		phase = (hour - SUNRISE_HOUR) / (SUNSET_HOUR - SUNRISE_HOUR) * PI
	else:
		var night_hours := 24.0 - (SUNSET_HOUR - SUNRISE_HOUR)
		phase = PI + fposmod(hour - SUNSET_HOUR, 24.0) / night_hours * PI
	var elevation := sin(phase) * deg_to_rad(SUN_MAX_ELEVATION if sin(phase) >= 0.0 else 70.0)
	var azimuth := cos(phase) * PI * 0.5 + deg_to_rad(SUN_AZIMUTH_TILT)
	return Vector3(cos(elevation) * sin(azimuth), sin(elevation), cos(elevation) * cos(azimuth)).normalized()

func _update_weather(delta: float) -> void:
	# Bulutluluk birkac dakikada bir yavasca degisir; ruzgar bulutlari tasir.
	_cloud_timer -= delta
	if _cloud_timer <= 0.0:
		_cloud_timer = _weather_random.randf_range(90.0, 240.0)
		_cloud_target = _weather_random.randf_range(0.25, 0.7)
	cloud_coverage = move_toward(cloud_coverage, _cloud_target, delta * 0.004)
	sky_material.set_shader_parameter("cloud_coverage", cloud_coverage)
	_cloud_offset += Vector2(0.0022, 0.0009) * delta
	sky_material.set_shader_parameter("cloud_offset", _cloud_offset)

func apply_time() -> void:
	if environment == null:
		return
	var sun_dir := sun_direction()
	var moon_dir := -sun_dir.rotated(Vector3.FORWARD, 0.25)
	var day := smoothstep(-0.14, 0.22, sun_dir.y)
	var sunset := (1.0 - smoothstep(0.0, 0.32, absf(sun_dir.y))) * smoothstep(-0.2, 0.0, sun_dir.y)
	var clouds := cloud_coverage

	sun.global_transform = Transform3D(Basis.looking_at(-sun_dir, Vector3.UP if absf(sun_dir.y) < 0.99 else Vector3.FORWARD), Vector3.ZERO)
	sun.light_color = Color(1.0, 0.62, 0.36).lerp(Color(1.0, 0.96, 0.9), clampf(sun_dir.y * 3.2, 0.0, 1.0))
	sun.light_energy = smoothstep(-0.03, 0.12, sun_dir.y) * lerpf(1.45, 1.05, clouds)
	sun.visible = sun_dir.y > -0.05
	moon.global_transform = Transform3D(Basis.looking_at(-moon_dir, Vector3.UP if absf(moon_dir.y) < 0.99 else Vector3.FORWARD), Vector3.ZERO)
	moon.light_energy = smoothstep(-0.02, 0.15, moon_dir.y) * 0.22 * (1.0 - day)
	moon.visible = moon.light_energy > 0.01

	sky_material.set_shader_parameter("sun_direction", sun_dir)
	sky_material.set_shader_parameter("moon_direction", moon_dir)
	sky_material.set_shader_parameter("day_factor", day)
	sky_material.set_shader_parameter("sunset_factor", sunset)

	environment.ambient_light_energy = lerpf(0.35, 1.0, day)
	environment.tonemap_exposure = lerpf(1.35, 1.0, day)
	var fog_day := Color(0.72, 0.8, 0.88)
	var fog_sunset := Color(0.95, 0.66, 0.45)
	var fog_night := Color(0.05, 0.07, 0.11)
	environment.fog_light_color = fog_night.lerp(fog_day, day).lerp(fog_sunset, sunset * 0.6)
	environment.fog_light_energy = lerpf(0.4, 1.0, day)
	# Sabah sisi: 5-9 arasi yogun, ogleye dogru acilir.
	var morning_mist := smoothstep(4.0, 6.0, hour) * (1.0 - smoothstep(7.0, 9.5, hour))
	environment.volumetric_fog_density = lerpf(0.004, 0.011, morning_mist) + 0.004 * (1.0 - day)
	environment.fog_density = lerpf(0.0016, 0.003, morning_mist)
	environment.volumetric_fog_albedo = Color(0.92, 0.94, 0.96).lerp(Color(1.0, 0.85, 0.72), sunset * 0.5)
