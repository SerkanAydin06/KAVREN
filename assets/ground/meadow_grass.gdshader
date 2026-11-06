shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 root_color : source_color = vec4(0.30, 0.49, 0.33, 1.0);
uniform vec4 blade_color : source_color = vec4(0.52, 0.67, 0.38, 1.0);
uniform vec4 herb_color : source_color = vec4(0.64, 0.74, 0.44, 1.0);
varying float breeze;
void vertex() {
	vec3 pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	breeze = sin(pos.x*0.57 + pos.z*0.31 + TIME*1.6);
	VERTEX.x += breeze*COLOR.r*0.046;
}
void fragment() {
	vec3 tip = mix(blade_color.rgb,herb_color.rgb,COLOR.g);
	ALBEDO = mix(root_color.rgb,tip,COLOR.r) * (0.96 + breeze*0.04);
}
