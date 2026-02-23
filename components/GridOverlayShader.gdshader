shader_type canvas_item;

uniform vec2 cell_size = vec2(256.0, 256.0);
uniform vec2 draw_size = vec2(1024.0, 1024.0);
uniform float line_thickness = 1.0;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.28);

void fragment() {
	vec2 local_pos = UV * draw_size;
	vec2 grid = abs(fract(local_pos / cell_size) - 0.5) * cell_size;
	float distance_to_line = min(grid.x, grid.y);
	float alpha = 1.0 - smoothstep(line_thickness, line_thickness + 1.0, distance_to_line);
	COLOR = vec4(line_color.rgb, line_color.a * alpha);
}