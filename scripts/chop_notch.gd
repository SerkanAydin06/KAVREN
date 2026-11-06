extends MeshInstance3D

# Balta centigi: govdeye oyulmus V-kesik. Ust yuz egik, alt yuz duz, uclara
# dogru incelen mercek bicimi ve govde egriligine oturan dis kenar.
# Yerel eksenler: +Z govde yuzeyinden disari (oyuncuya), +Y yukari, X teget.
# Govde opak oldugu icin kesik yuzeyleri gercekte kabugun arkasinda kalir;
# shader her noktayi kendi gorus isini boyunca kameraya cekerek kabugun
# onunde cizer. Ekrandaki sekli degismez, govdeye oyulmus gibi gorunur.

const SEGMENTS := 14

const NOTCH_SHADER := """
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
uniform float pull_to_camera = 0.2;
uniform float trunk_radius = 0.5;
uniform float ring_spacing = 0.035;
const vec3 WOOD_LIGHT = vec3(0.80, 0.56, 0.28);
const vec3 WOOD_RING = vec3(0.52, 0.31, 0.13);
const vec3 BARK_COLOR = vec3(0.07, 0.04, 0.02);
varying vec3 local_position;
void vertex() {
	local_position = VERTEX;
	vec4 view_position = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	float distance_to_camera = length(view_position.xyz);
	float pull = min(pull_to_camera, distance_to_camera * 0.5);
	view_position.xyz -= normalize(view_position.xyz) * pull;
	POSITION = PROJECTION_MATRIX * view_position;
}
void fragment() {
	// UV.x = 1: taze odun (halkali), 0: kabuk kenari. COLOR.r: golge carpani.
	float radial = length(vec2(local_position.x, local_position.z + trunk_radius));
	float wobble = sin(local_position.x * 31.0) * 0.004 + sin(local_position.y * 47.0) * 0.003;
	float rings = smoothstep(0.55, 0.95, abs(sin((radial + wobble) * 3.14159 / ring_spacing)));
	vec3 wood = mix(WOOD_LIGHT, WOOD_RING, rings * 0.6) * COLOR.r;
	ALBEDO = mix(BARK_COLOR, wood, step(0.5, UV.x));
	ROUGHNESS = 0.9;
}
"""

static var _shader: Shader

var trunk_radius := 0.5
var notch_width := 0.5
var notch_height := 0.2
var notch_depth := 0.1

func configure(radius: float) -> void:
	trunk_radius = maxf(radius, 0.12)
	notch_width = clampf(trunk_radius * 1.15, 0.2, 0.95)
	notch_height = notch_width * 0.5
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if _shader == null:
		_shader = Shader.new()
		_shader.code = NOTCH_SHADER
	var material := ShaderMaterial.new()
	material.shader = _shader
	material_override = material

# progress: 0..1 (son darbede ~1). Centik derinlesir ve biraz genisler.
func set_progress(progress: float) -> void:
	var p := clampf(progress, 0.05, 1.0)
	notch_depth = clampf(trunk_radius * (0.12 + 0.42 * p), 0.04, 0.45)
	var width := notch_width * (0.72 + 0.28 * p)
	var height := notch_height * (0.7 + 0.3 * p)
	mesh = _build(width, height, notch_depth)
	var material := material_override as ShaderMaterial
	material.set_shader_parameter("pull_to_camera", notch_depth + 0.04)
	material.set_shader_parameter("trunk_radius", trunk_radius)
	material.set_shader_parameter("ring_spacing", clampf(trunk_radius * 0.07, 0.018, 0.05))

func _surface_offset(x: float) -> float:
	# Silindir govdede merkezden x kadar yandaki yuzey biraz geride kalir.
	var r := trunk_radius
	return -(r - sqrt(maxf(r * r - x * x, 0.0)))

func _build(width: float, height: float, depth: float) -> ArrayMesh:
	# Gercek centik: alt kesim yatay ve duz, ust kesim egik iner; ikisi
	# icteki dip cizgisinde (crease) bulusur. Uclarda derinlik sifira iner.
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top_outer: Array[Vector3] = []
	var bottom_outer: Array[Vector3] = []
	var crease: Array[Vector3] = []
	var lip_top: Array[Vector3] = []
	var lip_bottom: Array[Vector3] = []
	var depth_factor: Array[float] = []
	var y_bottom := -height * 0.32
	for i in range(SEGMENTS + 1):
		var t := lerpf(-1.0, 1.0, float(i) / float(SEGMENTS))
		var taper := 1.0 - pow(absf(t), 1.8)
		var opening := pow(maxf(taper, 0.0), 0.75)
		var x := t * width * 0.5
		var z_surface := _surface_offset(x) + 0.003
		var y_top := y_bottom + height * opening
		top_outer.append(Vector3(x, y_top, z_surface))
		bottom_outer.append(Vector3(x, y_bottom, z_surface))
		crease.append(Vector3(x, y_bottom + height * 0.03 * opening, z_surface - depth * taper))
		var lip := 0.008 + 0.01 * opening
		lip_top.append(Vector3(x, y_top + lip, z_surface + 0.002))
		lip_bottom.append(Vector3(x, y_bottom - lip * 0.7, z_surface + 0.002))
		depth_factor.append(taper)
	# Renk kanali sadece golge carpani tasir (r=g=b); asil renk shader'da.
	var wood_top := Color(0.82, 0.82, 0.82) # ust egik yuz: hafif golgede
	var wood_bottom := Color(1.0, 1.0, 1.0)
	var crease_color := Color(0.28, 0.28, 0.28)
	var lip_color := Color(-1.0, 0.0, 0.0) # isaret: kabuk kenari
	for i in range(SEGMENTS):
		var ca := crease_color.lerp(wood_top, 1.0 - depth_factor[i] * 0.85)
		var cb := crease_color.lerp(wood_top, 1.0 - depth_factor[i + 1] * 0.85)
		_quad(tool, top_outer[i], top_outer[i + 1], crease[i + 1], crease[i], wood_top, wood_top, cb, ca)
		var da := crease_color.lerp(wood_bottom, 1.0 - depth_factor[i] * 0.6)
		var db := crease_color.lerp(wood_bottom, 1.0 - depth_factor[i + 1] * 0.6)
		_quad(tool, crease[i], crease[i + 1], bottom_outer[i + 1], bottom_outer[i], da, db, wood_bottom, wood_bottom)
		_quad(tool, lip_top[i], lip_top[i + 1], top_outer[i + 1], top_outer[i], lip_color, lip_color, lip_color, lip_color)
		_quad(tool, bottom_outer[i], bottom_outer[i + 1], lip_bottom[i + 1], lip_bottom[i], lip_color, lip_color, lip_color, lip_color)
	tool.generate_normals()
	return tool.commit()

func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
	var points := [a, b, c, a, c, d]
	var colors := [ca, cb, cc, ca, cc, cd]
	for i in range(6):
		var color: Color = colors[i]
		var is_bark := color.r < 0.0
		tool.set_uv(Vector2(0.0 if is_bark else 1.0, 0.0))
		tool.set_color(Color(1, 1, 1) if is_bark else color)
		tool.add_vertex(points[i])
