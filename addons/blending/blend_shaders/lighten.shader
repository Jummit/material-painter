shader_type canvas_item;

uniform float value = 1.0;

float blendLightenF(float base, float blend) {
	return max(blend,base);
}

vec3 blendLighten(vec3 base, vec3 blend) {
	return vec3(blendLightenF(base.r,blend.r),blendLightenF(base.g,blend.g),blendLightenF(base.b,blend.b));
}

vec3 blendLightenO(vec3 base, vec3 blend, float opacity) {
	return (blendLighten(base, blend) * opacity + base * (1.0 - opacity));
}

void fragment() {
	vec3 screen = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
	COLOR = vec4(blendLightenO(screen, texture(TEXTURE, UV).rgb, value), 1.0);
}
