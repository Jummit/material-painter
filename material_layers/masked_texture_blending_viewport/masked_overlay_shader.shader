shader_type canvas_item;

uniform sampler2D mask;

vec3 blendNormal(vec3 base, vec3 blend) {
	return blend;
}

vec3 blendNormalO(vec3 base, vec3 blend, float opacity) {
	return (blendNormal(base, blend) * opacity + base * (1.0 - opacity));
}

void fragment() {
	vec3 screen = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
	COLOR = vec4(blendNormalO(screen, texture(TEXTURE, UV).rgb, texture(mask, UV).r), 1.0);
}