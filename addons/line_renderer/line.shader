shader_type canvas_item;

uniform vec2 a;
uniform vec2 b;
uniform vec4 col : hint_color = vec4(1.0);
uniform float size = 0.05;

void fragment() {
	vec2 l = b - a;
	vec2 pa = SCREEN_UV - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
	
	COLOR = col;
	COLOR.a = 1.0 - clamp(length(pa - ba * h) / size, 0, 1);
}