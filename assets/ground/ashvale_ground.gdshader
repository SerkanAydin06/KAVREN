shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform sampler2D ground_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float meters_per_tile = 4.0;
uniform vec2 camp_center;
uniform vec2 mine_entry;
uniform vec4 meadow_dark : source_color = vec4(0.32, 0.53, 0.39, 1.0);
uniform vec4 meadow_light : source_color = vec4(0.58, 0.72, 0.41, 1.0);
uniform vec4 dry_clay : source_color = vec4(0.88, 0.68, 0.43, 1.0);
uniform vec4 trail_edge : source_color = vec4(0.61, 0.57, 0.33, 1.0);
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
    vec2 p = terrain_world_uv;
    float patch_value = smooth_noise(p * 0.24) * 0.65 + smooth_noise(p * 0.06) * 0.35;
    float meadow = smoothstep(0.20, 0.82, patch_value);
    vec3 grass = mix(meadow_dark.rgb, meadow_light.rgb, meadow);
    float t = clamp((p.y - camp_center.y) / (mine_entry.y - camp_center.y), 0.0, 1.0);
    vec2 trail = mix(camp_center, mine_entry, t);
    trail.x += sin(t * 6.28318) * 3.0;
    float path_dist = length(p - trail) - 1.65;
    float clearing_dist = length((p - camp_center) * vec2(0.86, 1.0)) - 5.0;
    float bank = min(path_dist, clearing_dist) + (patch_value - 0.5) * 1.4;
    // Use broad changes of hue and a staggered second sample to hide the tile repeat.
    vec2 uv = p / meters_per_tile;
    float grain = mix(texture(ground_albedo, uv).g,
                      texture(ground_albedo, vec2(-uv.y, uv.x) * 0.71 + vec2(0.28, 0.61)).g, meadow);
    float verge = smoothstep(-0.35, 0.65, bank);
    vec3 path = mix(dry_clay.rgb, trail_edge.rgb, smoothstep(-0.75, 0.08, bank) * 0.55);
    ALBEDO = mix(path, grass, verge) * (0.975 + grain * 0.055);
    ROUGHNESS = 1.0;
    SPECULAR = 0.06;
}
