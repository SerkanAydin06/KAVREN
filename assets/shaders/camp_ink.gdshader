shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform vec4 paint : source_color = vec4(1.0);
uniform bool vertex_paint = false;
uniform bool foliage = false;
uniform float ink_width = 0.06;
varying vec3 local_point;
varying vec3 local_normal;

void vertex() {
    local_point = VERTEX;
    local_normal = NORMAL;
    if (foliage) {
        float phase = MODEL_MATRIX[3].x * 0.45 + MODEL_MATRIX[3].z * 0.24;
        float tip = smoothstep(-0.8, 0.8, VERTEX.y);
        VERTEX.x += tip * (0.042 * sin(TIME * 1.65 + phase) + 0.022 * sin(TIME * 2.3 + phase * 1.4));
    }
}

void fragment() {
    vec3 base = paint.rgb;
    if (vertex_paint) {
        base *= OUTPUT_IS_SRGB ? COLOR.rgb : pow(max(COLOR.rgb, vec3(0.0)), vec3(2.2));
    }
    if (foliage) {
        vec2 p = local_point.xz * 4.0 + local_point.yy * vec2(0.4, 0.7);
        float mark = sin(p.x * 1.8 + sin(p.y * 1.4)) + 0.65 * cos(2.8 * p.y + p.x);
        float dab = smoothstep(0.98, 1.13, mark) * smoothstep(0.07, 0.55, local_normal.y);
        base *= mix(vec3(1.0), vec3(1.28, 1.16, 0.88), dab);
    }
    float angle = abs(dot(normalize(NORMAL), normalize(VIEW)));
    float outline = 1.0 - smoothstep(ink_width, ink_width + max(fwidth(angle), 0.03), angle);
    ALBEDO = mix(base, base * vec3(0.30, 0.37, 0.46), outline * 0.62);
    ROUGHNESS = 1.0;
}

void light() {
    float band = smoothstep(0.12, 0.34, dot(normalize(NORMAL), LIGHT));
    DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR * mix(0.11, 0.85, band) / PI;
}
