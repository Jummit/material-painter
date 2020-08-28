shader_type canvas_item;

uniform float value = 1.0;

float blendSoftLightF(float base, float blend) {
	return (blend<0.5)?(2.0*base*blend+base*base*(1.0-2.0*blend)):(sqrt(base)*(2.0*blend-1.0)+2.0*base*(1.0-blend));
}

vec3 blendSoftLight(vec3 base, vec3 blend) {
	return vec3(blendSoftLightF(base.r,blend.r),blendSoftLightF(base.g,blend.g),blendSoftLightF(base.b,blend.b));
}

vec3 blendSoftLightO(vec3 base, vec3 blend, float opacity) {
	return (blendSoftLight(base, blend) * opacity + base * (1.0 - opacity));
}

void fragment() {
	vec3 screen = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
	COLOR = vec4(blendSoftLightO(screen, texture(TEXTURE, UV).rgb, value), 1.0);
}
