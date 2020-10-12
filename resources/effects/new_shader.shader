shader_type canvas_item;

vec4 iou(vec2 uv) {
	vec2 radius = 0.002 / vec2(3.0);
	vec4 oute = {previous}(uv);
	for(float d = 0.0; d < 6.28318530718; d += 6.28318530718 / float(16)) {
		for(float i = 1.0 / 8.0; i <= 1.0; i += 1.0 / 8.0) {
			oute += {previous}(uv + vec2(cos(d), sin(d)) * radius * i, 0.0);
		}
	}
	out /= 8.0 * float(16) + 1.0;
	return oute;
}