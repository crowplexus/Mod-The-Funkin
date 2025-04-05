shader_type canvas_item;
instance uniform vec3 new_color: source_color = vec3(1, 1, 1);
instance uniform bool enabled = false;
// yoinked https://github.com/CodenameCrew/YoshiCrafterEngine/blob/9d6b4209a855b5b27d52a20d3ea2b1f4c3a51171/source/NoteShader.hx#L3
void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float diff = color.r - (color.g + color.b) * 0.5;
	vec3 result = vec3(
		((color.g + color.b) * 0.5) + (new_color.r * diff),
		color.g + (new_color.g * diff),
		color.b + (new_color.b * diff));
	COLOR = vec4(mix(color.rgb, result, float(enabled)), color.a);
}
