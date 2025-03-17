shader_type canvas_item;
uniform vec4 regular_color: source_color = vec4(1.0, 1.0, 1.0, 0.5);
uniform vec4 quarter_color: source_color = vec4(1.0, 1.0, 1.0, 0.8);
uniform float regular_thickness = 0.002;
uniform float quarter_thickness = 0.003;
uniform int lines_below = 16;
uniform float offset = 0.0;
void fragment() {
	float uvy = UV.y + offset;
	float line_position = floor(uvy * float(lines_below)) / float(lines_below);
	bool is_quarter_line = mod(line_position * float(lines_below), 4.0) == 0.0;
	float thickness = is_quarter_line ? quarter_thickness : regular_thickness;
	COLOR = (abs(uvy - line_position) < thickness) ? is_quarter_line ? quarter_color : regular_color : COLOR;
}