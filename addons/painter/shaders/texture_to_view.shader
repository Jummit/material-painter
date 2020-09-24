shader_type spatial;
render_mode unshaded, cull_front;

uniform sampler2D view_to_texture;
uniform mat4 model_transform;
uniform float fovy_degrees = 45;
uniform float z_near = 0.01;
uniform float z_far = 60.0;
uniform float aspect = 1.0;

varying vec4 global_position;
varying vec3 normal;

mat4 get_projection_matrix() {
	float PI = 3.14159265359;
	
	float rads = fovy_degrees / 2.0 * PI / 180.0;

	float deltaZ = z_far - z_near;
	float sine = sin(rads);

	if (deltaZ == 0.0 || sine == 0.0 || aspect == 0.0)
		return mat4(0.0);
	
	float cotangent = cos(rads) / sine;

	mat4 matrix = mat4(1.0);
	matrix[0][0] = cotangent / aspect;
	matrix[1][1] = cotangent;
	matrix[2][2] = (z_far + z_near) / deltaZ;
	matrix[2][3] = 1.0; //try +1
	matrix[3][2] = 2.0 * z_near * z_far / deltaZ; 
	
	matrix[3][3] = 0.0;
	
	return matrix;
}

void vertex() {
	global_position = model_transform*vec4(VERTEX, 1.0);
	normal = (model_transform * vec4(NORMAL, 0.0)).xyz;
	VERTEX=vec3(UV.x, UV.y, 0.0);
	COLOR=vec4(1.0);
}

float visibility(vec2 uv, vec3 view_pos) {
	vec2 uv_delta = textureLod(view_to_texture, view_pos.xy, 0.0).xy-uv;
	return step(dot(uv_delta, uv_delta), 0.0025);
}

void fragment() {
	vec4 position = get_projection_matrix() * vec4(global_position.xyz, 1.0);
	position.xyz /= position.w;
	vec3 xyz = vec3(0.5 - 0.5 * position.x, 0.5 + 0.5 * position.y, z_near + (z_far - z_near) * position.z);
	float visible = 0.0;
	if (position.x > -1.0 && position.x < 1.0 && position.y > -1.0 && position.y < 1.0) {
		float visibility_multiplier = max(visibility(UV.xy, xyz), max(max(visibility(UV.xy, xyz + vec3(0.001, 0.0, 0.0)), visibility(UV.xy, xyz + vec3(-0.0001, 0.0, 0.0))),  max(visibility(UV.xy, xyz + vec3(0.0, 0.001, 0.0)), visibility(UV.xy, xyz + vec3(0.0, -0.0001, 0.0)))));
		//float visibility_multiplier = visibility(UV.xy, xyz);
		float normal_multiplier = clamp(dot(normalize(normal), vec3(0.0, 0.0, 1.0)), 0.0, 1.0);
		visible = normal_multiplier * visibility_multiplier;
	}
	ALBEDO = vec3(xyz.xy, visible);
}
