shader_type canvas_item;

// This special hint tells Godot we want to read what's behind this node.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// The blur amount. We can change this in the Inspector later!
uniform float blur_amount : hint_range(0.0, 5.0) = 2.5;

void fragment() {
	// Sample the screen texture at the current pixel position.
	// The third argument 'blur_amount' specifies the Mipmap Level of Detail (LOD).
	// Higher LOD levels are inherently blurrier versions of the texture.
	vec4 color = textureLod(screen_texture, SCREEN_UV, blur_amount);

	// Apply the blurred color to this layer.
	COLOR = color;
}