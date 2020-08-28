shader_type canvas_item;

uniform float value = 1.0;

float blendColorDodgeF(float base, float blend) {
	return (blend==1.0)?blend:min(base/(1.0-blend),1.0);
}

vec3 blendColorDodge(vec3 base, vec3 blend) {
	return vec3(blendColorDodgeF(base.r,blend.r),blendColorDodgeF(base.g,blend.g),blendColorDodgeF(base.b,blend.b));
}

vec3 blendColorDodgeO(vec3 base, vec3 blend, float opacity) {
	return (blendColorDodge(base, blend) * opacity + base * (1.0 - opacity));
}

void fragment() {
	vec3 screen = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
	COLOR = vec4(blendColorDodgeO(texture(TEXTURE, UV).rgb, screen, value), 1.0);
}
