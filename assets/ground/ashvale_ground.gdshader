shader_type spatial;
render_mode cull_back, depth_draw_opaque;

// Ashvale — arazi icin yerel-gosterim PBR materyal.
// Yuzey uzerindeki UV'ler yerine dunya koordinatlariyla dosemek:
// boyut artarken kaplama gerilmez; her 4 metrede tekrar eder.
uniform sampler2D ground_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float meters_per_tile : hint_range(1.0, 16.0, 0.5) = 4.0;
uniform float macro_variation : hint_range(0.0, 0.6, 0.01) = 0.26;
uniform float bump_intensity : hint_range(0.0, 1.0, 0.01) = 0.18;
varying vec2 terrain_world_uv;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float smooth_noise(vec2 p) {
    vec2 cell = floor(p);
    vec2 f = fract(p);
    vec2 smooth_f = f * f * (3.0 - 2.0 * f);
    float a = hash21(cell);
    float b = hash21(cell + vec2(1.0, 0.0));
    float c = hash21(cell + vec2(0.0, 1.0));
    float d = hash21(cell + vec2(1.0, 1.0));
    return mix(mix(a, b, smooth_f.x), mix(c, d, smooth_f.x), smooth_f.y);
}

void vertex() {
    terrain_world_uv = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
    // 160 x 160 metre zeminin her noktasinda sabit dunya olceginde doku.
    vec2 tile_uv = terrain_world_uv / meters_per_tile;
    float wide_noise = smooth_noise(terrain_world_uv * 0.055);
    float local_noise = smooth_noise(terrain_world_uv * 0.17 + vec2(9.1, 3.7));
    float macro = wide_noise * 0.72 + local_noise * 0.28;

    vec3 base_color = texture(ground_albedo, tile_uv).rgb;
    vec3 alternate = texture(ground_albedo, tile_uv * 0.83 + vec2(0.31, 0.61)).rgb;
    float breakup = smoothstep(0.31, 0.75, macro) * macro_variation;
    vec3 soil = mix(base_color, alternate, breakup);
    soil *= mix(0.87, 1.08, macro);

    // Renk dokusunun hafif yukseklik farklarindan mikroyuzey hissi.
    vec2 texel = vec2(1.0 / 1024.0);
    vec3 lum_weights = vec3(0.299, 0.587, 0.114);
    float h_left = dot(texture(ground_albedo, tile_uv - vec2(texel.x, 0.0)).rgb, lum_weights);
    float h_right = dot(texture(ground_albedo, tile_uv + vec2(texel.x, 0.0)).rgb, lum_weights);
    float h_down = dot(texture(ground_albedo, tile_uv - vec2(0.0, texel.y)).rgb, lum_weights);
    float h_up = dot(texture(ground_albedo, tile_uv + vec2(0.0, texel.y)).rgb, lum_weights);
    NORMAL_MAP = normalize(vec3((h_left - h_right) * 3.0, (h_down - h_up) * 3.0, 1.0));
    NORMAL_MAP_DEPTH = bump_intensity;
    ALBEDO = soil;
    ROUGHNESS = 0.94;
    SPECULAR = 0.18;
    METALLIC = 0.0;
}
