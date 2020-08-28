shader_type canvas_item;

uniform float value = 1.0;

vec3 blendNormal(vec3 base, vec3 blend) {
	return blend;
}

vec3 blendNormalO(vec3 base, vec3 blend, float opacity) {
	return (blendNormal(base, blend) * opacity + base * (1.0 - opacity));
}

void fragment() {
	vec3 screen = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
	COLOR = vec4(blendNormalO(texture(TEXTURE, UV).rgb, screen, value), 1.0);
}
