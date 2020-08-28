shader_type canvas_item;

uniform float value = 1.0;

float blendDarkenF(float base, float blend) {
	return min(blend,base);
}

vec3 blendDarken(vec3 base, vec3 blend) {
	return vec3(blendDarkenF(base.r,blend.r),blendDarkenF(base.g,blend.g),blendDarkenF(base.b,blend.b));
}

vec3 blendDarkenO(vec3 base, vec3 blend, float opacity) {
	return (blendDarken(base, blend) * opacity + base * (1.0 - opacity));
}

void fragment() {
	vec3 screen = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
	COLOR = vec4(blendDarkenO(texture(TEXTURE, UV).rgb, screen, value), 1.0);
}
