shader_type canvas_item;

uniform vec4 key_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float similarity : hint_range(0.0, 1.0) = 0.1;
uniform float smoothness : hint_range(0.0, 1.0) = 0.08;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    float d = distance(color.rgb, key_color.rgb);
    float mask = smoothstep(similarity, similarity + smoothness, d);
    COLOR = vec4(color.rgb, color.a * mask);
}
