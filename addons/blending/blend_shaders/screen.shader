shader_type canvas_item;

uniform float value = 1.0;

float blendScreenF(float base, float blend) {
	return 1.0-((1.0-base)*(1.0-blend));
}

vec3 blendScreen(vec3 base, vec3 blend) {
	return vec3(blendScreenF(base.r,blend.r),blendScreenF(base.g,blend.g),blendScreenF(base.b,blend.b));
}

vec3 blendScreenO(vec3 base, vec3 blend, float opacity) {
	return (blendScreen(base, blend) * opacity + base * (1.0 - opacity));
}

void fragment() {
	vec3 screen = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
	COLOR = vec4(blendScreenO(texture(TEXTURE, UV).rgb, screen, value), 1.0);
}
