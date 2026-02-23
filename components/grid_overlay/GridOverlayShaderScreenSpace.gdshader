shader_type canvas_item;

uniform vec2 cell_size = vec2(256.0, 256.0);
uniform vec2 draw_size = vec2(1024.0, 1024.0);
uniform float line_thickness_pixels = 1.0;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.28);

void fragment() {
	vec2 local_pos = UV * draw_size;
	vec2 cell_pos = mod(local_pos, cell_size);
	vec2 dist_to_line_world = min(cell_pos, cell_size - cell_pos);
	float distance_world = min(dist_to_line_world.x, dist_to_line_world.y);

	vec2 ddx_local = dFdx(local_pos);
	vec2 ddy_local = dFdy(local_pos);
	float world_per_pixel = max(length(ddx_local), length(ddy_local));
	world_per_pixel = max(world_per_pixel, 0.0001);

	float thickness_world = line_thickness_pixels * world_per_pixel;
	float aa_world = world_per_pixel;
	float alpha = 1.0 - smoothstep(thickness_world, thickness_world + aa_world, distance_world);

	COLOR = vec4(line_color.rgb, line_color.a * alpha);
}