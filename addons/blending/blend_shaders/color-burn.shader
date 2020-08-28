shader_type canvas_item;

uniform float value = 1.0;

float blendColorBurnF(float base, float blend) {
	return (blend==0.0)?blend:max((1.0-((1.0-base)/blend)),0.0);
}

vec3 blendColorBurn(vec3 base, vec3 blend) {
	return vec3(blendColorBurnF(base.r,blend.r),blendColorBurnF(base.g,blend.g),blendColorBurnF(base.b,blend.b));
}

vec3 blendColorBurnO(vec3 base, vec3 blend, float opacity) {
	return (blendColorBurn(base, blend) * opacity + base * (1.0 - opacity));
}

void fragment() {
	vec3 screen = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
	COLOR = vec4(blendColorBurnO(texture(TEXTURE, UV).rgb, screen, value), 1.0);
}
