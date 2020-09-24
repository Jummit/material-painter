shader_type canvas_item;
render_mode blend_disabled, unshaded;

uniform sampler2D texture_to_view;
uniform sampler2D seams : hint_white;

uniform vec2 brush_pos = vec2(0.5, 0.5);
uniform vec2 brush_ppos = vec2(0.5, 0.5);
uniform vec2 brush_size = vec2(0.25, 0.25);
uniform float brush_strength = 1.0;
uniform sampler2D brush_texture : hint_white;
uniform vec4 brush_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float pattern_scale = 10.0;
uniform float texture_angle = 0.0;
uniform bool stamp_mode = false;
uniform vec4 texture_mask = vec4(1.0, 1.0, 1.0, 1.0);

float brush(float v) {
	return clamp(v / (1.0 - brush_strength), 0.0, 1.0);
}

vec4 pattern_color(vec2 uv) {
	mat2 texture_rotation = mat2(vec2(cos(texture_angle), sin(texture_angle)), vec2( - sin(texture_angle), cos(texture_angle)));
	vec2 pattern_uv = pattern_scale * texture_rotation * (vec2(brush_size.y / brush_size.x, 1.0) * (uv - vec2(0.5, 0.5)));
	return texture(brush_texture, fract(pattern_uv));
}

void fragment() {
	// Get UV from seams texture
	vec2 uv = UV + (texture(seams, UV).xy - vec2(0.5)) / 64.0;
	// Get View position
	vec4 tex2view = texture(texture_to_view, uv);
	vec2 xy = tex2view.xy;
	// Get distance to brush center
	vec2 b = brush_pos / brush_size;
	vec2 bv = (brush_ppos - brush_pos) / brush_size;
	vec2 p = xy / brush_size;
	float x = clamp(dot(p - b, bv) / dot(bv, bv), 0.0, 1.0);
	// Get position in brush
	vec2 local_uv = p - (b + x * bv);
	float a;
	vec4 color;
	if (stamp_mode) {
		mat2 texture_rotation = mat2(vec2(cos(texture_angle), sin(texture_angle)), vec2( - sin(texture_angle), cos(texture_angle)));
		local_uv = texture_rotation * local_uv;
		vec2 stamp_limit = step(abs(local_uv), vec2(1.0));
		a = stamp_limit.x * stamp_limit.y;
		color = texture(brush_texture, 0.5 * local_uv + vec2(0.5));
	} else {
		a = brush(max(0.0, 1.0 - length(local_uv)));
		color = pattern_color(xy);
	}
	color = brush_color * color * texture_mask + brush_color * (vec4(1.0) - texture_mask);
	a *= color.a * tex2view.z;
	vec4 screen_color = texture(SCREEN_TEXTURE, UV);
	float alpha_sum = min(1.0, a + screen_color.a);
 	COLOR = vec4((color.xyz * a + screen_color.xyz * (vec3(alpha_sum) - a)) / alpha_sum, alpha_sum);
}
