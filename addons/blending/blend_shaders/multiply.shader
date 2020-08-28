shader_type canvas_item;

uniform float value = 1.0;

vec3 blendMultiplyF(vec3 base, vec3 blend) {
	return base*blend;
}

vec3 blendMultiply(vec3 base, vec3 blend, float opacity) {
	return (blendMultiplyF(base, blend) * opacity + base * (1.0 - opacity));
}

void fragment() {
	vec3 screen = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
	COLOR = vec4(blendMultiply(texture(TEXTURE, UV).rgb, screen, value), 1.0);
}
