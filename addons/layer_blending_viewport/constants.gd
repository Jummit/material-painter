"""
String templates used to generate blending shaders

Blending mode shaders from `https://github.com/jamieowen/glsl-blend`.
"""

const GENERATOR_FUNCTION_TEMPLATE := """vec4 {name}(vec2 uv) {
	{code}
}"""

const SHADER_TEMPLATE := """shader_type canvas_item;

{uniform_declaration}
{blend_shaders}
{generator_functions}
void fragment() {
	COLOR = {result_func}(UV);
}
"""

const BLEND_SHADERS := """vec4 blendmultiplyf(vec4 base, vec4 blend) {
	return base * blend;
}

vec4 blendmultiply(vec4 base, vec4 blend, float opacity) {
	return (blendmultiplyf(base, blend) * opacity + base * (1.0 - opacity));
}


float blenddarkenf(float base, float blend) {
	return min(blend, base);
}

vec4 blenddarkenb(vec4 base, vec4 blend) {
	return vec4(blenddarkenf(base.r, blend.r), blenddarkenf(base.g, blend.g), blenddarkenf(base.b, blend.b), base.a);
}

vec4 blenddarken(vec4 base, vec4 blend, float opacity) {
	return (blenddarkenb(base, blend) * opacity + base * (1.0 - opacity));
}


float blendcolordodgef(float base, float blend) {
	return (blend==1.0)?blend:min(base/(1.0-blend), 1.0);
}

vec4 blendcolordodgeb(vec4 base, vec4 blend) {
	return vec4(blendcolordodgef(base.r, blend.r), blendcolordodgef(base.g, blend.g), blendcolordodgef(base.b, blend.b), base.a);
}

vec4 blendcolordodge(vec4 base, vec4 blend, float opacity) {
	return (blendcolordodgeb(base, blend) * opacity + base * (1.0 - opacity));
}


float blendcolorburnf(float base, float blend) {
	return (blend == 0.0) ? blend : max((1.0 - ((1.0 - base) / blend)), 0.0);
}

vec4 blendcolorburnb(vec4 base, vec4 blend) {
	return vec4(blendcolorburnf(base.r, blend.r), blendcolorburnf(base.g, blend.g), blendcolorburnf(base.b, blend.b), base.a);
}

vec4 blendcolorburn(vec4 base, vec4 blend, float opacity) {
	return (blendcolorburnb(base, blend) * opacity + base * (1.0 - opacity));
}


vec4 blenddifferenceb(vec4 base, vec4 blend) {
	return abs(base-blend);
}

vec4 blenddifference(vec4 base, vec4 blend, float opacity) {
	return (blenddifferenceb(base, blend) * opacity + base * (1.0 - opacity));
}


float blendscreenf(float base, float blend) {
	return 1.0 - ((1.0 - base) * (1.0 - blend));
}

vec4 blendscreenb(vec4 base, vec4 blend) {
	return vec4(blendscreenf(base.r, blend.r), blendscreenf(base.g, blend.g), blendscreenf(base.b, blend.b), base.a);
}

vec4 blendscreen(vec4 base, vec4 blend, float opacity) {
	return (blendscreenb(base, blend) * opacity + base * (1.0 - opacity));
}


vec4 blendnormalb(vec4 base, vec4 blend) {
	return blend;
}

vec4 blendnormal(vec4 base, vec4 blend, float opacity) {
	return (blendnormalb(base, blend) * opacity + base * (1.0 - opacity));
}


float blendsubtractf(float base, float blend) {
	return max(base + blend - 1.0, 0.0);
}

vec4 blendsubtractb(vec4 base, vec4 blend) {
	return max(base + blend - vec4(1.0), vec4(0.0));
}

vec4 blendsubtract(vec4 base, vec4 blend, float opacity) {
	return (blendsubtractb(base, blend) * opacity + base * (1.0 - opacity));
}


float blendlightenf(float base, float blend) {
	return max(blend, base);
}

vec4 blendlightenb(vec4 base, vec4 blend) {
	return vec4(blendlightenf(base.r, blend.r), blendlightenf(base.g, blend.g), blendlightenf(base.b, blend.b), base.a);
}

vec4 blendlighten(vec4 base, vec4 blend, float opacity) {
	return (blendlightenb(base, blend) * opacity + base * (1.0 - opacity));
}


float blendaddf(float base, float blend) {
	return min(base+blend, 1.0);
}

vec4 blendaddb(vec4 base, vec4 blend) {
	return min(base+blend, vec4(1.0));
}

vec4 blendadd(vec4 base, vec4 blend, float opacity) {
	return (blendaddb(base, blend) * opacity + base * (1.0 - opacity));
}


float blendsoftlightf(float base, float blend) {
	return (blend < 0.5) ? (2.0 * base * blend + base * base * (1.0 - 2.0 * blend)) : (sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base *(1.0 - blend));
}

vec4 blendsoftlightb(vec4 base, vec4 blend) {
	return vec4(blendsoftlightf(base.r, blend.r), blendsoftlightf(base.g, blend.g), blendsoftlightf(base.b, blend.b), base.a);
}

vec4 blendsoftlight(vec4 base, vec4 blend, float opacity) {
	return (blendsoftlightb(base, blend) * opacity + base * (1.0 - opacity));
}


float blendoverlayf(float base, float blend) {
	return base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend));
}

vec4 blendoverlayb(vec4 base, vec4 blend) {
	return vec4(blendoverlayf(base.r, blend.r), blendoverlayf(base.g, blend.g), blendoverlayf(base.b, blend.b), base.a);
}

vec4 blendoverlay(vec4 base, vec4 blend, float opacity) {
	return (blendoverlayb(base, blend) * opacity + base * (1.0 - opacity));
}
"""
