shader_type spatial;
render_mode cull_disabled;
uniform vec4 deep : source_color = vec4(0.19,0.54,0.53,1.0);
uniform vec4 shore : source_color = vec4(0.55,0.79,0.65,1.0);
void fragment() {
	vec2 p = (UV - 0.5) * 2.14;
	float d = length(p);
	if (d > 1.0) { discard; }
	float glint = smoothstep(0.88,0.99,sin(p.y*24.0 + p.x*3.0 + TIME*1.3))
		* smoothstep(0.55,0.96,sin(p.x*10.0 - p.y*4.0 + TIME*0.4));
	ALBEDO = mix(deep.rgb,shore.rgb,smoothstep(0.4,0.96,d)) + glint*0.13;
	ROUGHNESS = 0.38;
}
