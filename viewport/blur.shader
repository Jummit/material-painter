shader_type canvas_item;

uniform float strength = 8.0;
uniform float quality = 3.0;

const float PI = 6.28318530718;
const float DIRECTIONS = 16.0;

void fragment() {
	vec2 radius = strength / (1.0 / SCREEN_PIXEL_SIZE.xy);
	vec2 uv = FRAGCOORD.xy / (1.0 / SCREEN_PIXEL_SIZE.xy);
	COLOR = texture(TEXTURE, uv);
	for(float d = 0.0; d < PI; d += PI / DIRECTIONS) {
		for(float i = 1.0 / quality; i <= 1.0; i += 1.0 / quality) {
			COLOR += texture(TEXTURE, uv + vec2(cos(d), sin(d)) * radius * i);
		}
	}
	COLOR /= quality * DIRECTIONS - 15.0;
}