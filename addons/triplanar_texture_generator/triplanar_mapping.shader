shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D albedo : hint_albedo;
varying vec3 uv_triplanar_pos;
uniform float uv_blend_sharpness = 5.0;
varying vec3 uv_power_normal;
uniform vec3 uv_scale = vec3(1.0);
uniform vec3 uv_offset = vec3(0.0);

void vertex() {
	uv_power_normal = pow(abs(NORMAL), vec3(uv_blend_sharpness));
	uv_power_normal /= dot(uv_power_normal, vec3(1.0));
	uv_triplanar_pos = VERTEX * uv_scale + uv_offset;
	uv_triplanar_pos *= vec3(1.0,-1.0, 1.0);
	
	VERTEX.xy = UV;
	VERTEX.z = 0.0;
}

void fragment() {
	vec4 color = vec4(0.0);
	color += texture(albedo, uv_triplanar_pos.xy) * uv_power_normal.z;
	color += texture(albedo, uv_triplanar_pos.xz) * uv_power_normal.y;
	color += texture(albedo, uv_triplanar_pos.zy * vec2(-1.0, 1.0)) * uv_power_normal.x;
	ALBEDO = color.rgb;
}
