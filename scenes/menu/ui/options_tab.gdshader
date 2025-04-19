shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 coolUV = vec2((-SCREEN_UV.x), -SCREEN_UV.y + 1.0 + (sin(-((SCREEN_UV.x / 2.0)*50.0 * SCREEN_UV.y)+(SCREEN_UV.x+TIME*2.0)+TIME) / 55.0));
	vec4 tex = texture(SCREEN_TEXTURE, coolUV);
	COLOR = mix(tex, vec4(0.0,0.0,0.0,0.0), 0.7);
}