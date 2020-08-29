shader_type canvas_item;

uniform sampler2D mask;

float blendOverlayF(float base, float blend) {
	return base<0.5?(2.0*base*blend):(1.0-2.0*(1.0-base)*(1.0-blend));
}

vec3 blendOverlay(vec3 base, vec3 blend) {
	return vec3(blendOverlayF(base.r,blend.r),blendOverlayF(base.g,blend.g),blendOverlayF(base.b,blend.b));
}

vec3 blendOverlayO(vec3 base, vec3 blend, float opacity) {
	return (blendOverlay(base, blend) * opacity + base * (1.0 - opacity));
}

void fragment() {
	vec3 screen = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
	COLOR = vec4(blendOverlayO(screen, texture(TEXTURE, UV).rgb, texture(mask, UV).r), 1.0);
}