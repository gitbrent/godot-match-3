shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1, 1, 1, 1);
uniform float line_thickness : hint_range(0, 10) = 4.0;

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * line_thickness;
    float outline = 0.0;
    float total = 0.0;

    for (float x = -1.0; x <= 1.0; x += 1.0) {
        for (float y = -1.0; y <= 1.0; y += 1.0) {
            vec2 offset = vec2(x, y) * size;
            float sample_alpha = texture(TEXTURE, UV + offset).a;
            float weight = 1.0 - length(offset) / length(size);
            outline += sample_alpha * weight;
            total += weight;
        }
    }

    outline = outline / total;

    vec4 color = texture(TEXTURE, UV);
    COLOR = mix(color, line_color, outline - color.a);
}
