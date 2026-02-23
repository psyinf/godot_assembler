shader_type canvas_item;

uniform vec2 viewport_size = vec2(1920.0, 1080.0);
uniform vec2 origin_screen_pos = vec2(960.0, 540.0);
uniform float line_width_pixels = 0.8;
uniform vec4 x_axis_color : source_color = vec4(1.0, 0.25, 0.25, 0.85);
uniform vec4 y_axis_color : source_color = vec4(0.25, 1.0, 0.25, 0.85);

void fragment() {
	vec2 screen_pos = SCREEN_UV * viewport_size;

	float pixel_distance_x = abs(screen_pos.x - origin_screen_pos.x);
	float pixel_distance_y = abs(screen_pos.y - origin_screen_pos.y);

	float axis_x = 1.0 - smoothstep(line_width_pixels, line_width_pixels + 1.0, pixel_distance_x);
	float axis_y = 1.0 - smoothstep(line_width_pixels, line_width_pixels + 1.0, pixel_distance_y);

	vec4 x_color = vec4(x_axis_color.rgb, x_axis_color.a * axis_y);
	vec4 y_color = vec4(y_axis_color.rgb, y_axis_color.a * axis_x);

	float alpha_sum = x_color.a + y_color.a;
	float alpha = max(x_color.a, y_color.a);
	vec3 rgb = vec3(0.0);
	if (alpha_sum > 0.0001) {
		rgb = (x_color.rgb * x_color.a + y_color.rgb * y_color.a) / alpha_sum;
	}

	COLOR = vec4(rgb, alpha);
}