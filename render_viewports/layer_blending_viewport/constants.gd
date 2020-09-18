const BLEND_TEMPLATE := "	vec3 {result} = blend{mode}({a}, {b}, {opacity});"
const MASKED_BLEND_TEMPLATE := "	vec3 {result} = blend{mode}({a}, {b}, texture({opacity}, UV).r);"
const RESULT_TEMPLATE := "	vec3 {result} = {code};"

const SHADER_TEMPLATE := """shader_type canvas_item;

{uniform_declaration}
{blend_shaders}
void fragment() {
{preparing_code}
{blending_code}
	COLOR = vec4({result}, 1.0);
}
"""

const BLEND_SHADERS := """vec3 blendmultiplyf(vec3 base, vec3 blend) {
	return base * blend;
}

vec3 blendmultiply(vec3 base, vec3 blend, float opacity) {
	return (blendmultiplyf(base, blend) * opacity + base * (1.0 - opacity));
}


float blenddarkenf(float base, float blend) {
	return min(blend, base);
}

vec3 blenddarkenb(vec3 base, vec3 blend) {
	return vec3(blenddarkenf(base.r, blend.r), blenddarkenf(base.g, blend.g), blenddarkenf(base.b, blend.b));
}

vec3 blenddarken(vec3 base, vec3 blend, float opacity) {
	return (blenddarkenb(base, blend) * opacity + base * (1.0 - opacity));
}


float blendcolordodgef(float base, float blend) {
	return (blend==1.0)?blend:min(base/(1.0-blend), 1.0);
}

vec3 blendcolordodgeb(vec3 base, vec3 blend) {
	return vec3(blendcolordodgef(base.r, blend.r), blendcolordodgef(base.g, blend.g), blendcolordodgef(base.b, blend.b));
}

vec3 blendcolordodge(vec3 base, vec3 blend, float opacity) {
	return (blendcolordodgeb(base, blend) * opacity + base * (1.0 - opacity));
}


float blendcolorburnf(float base, float blend) {
	return (blend == 0.0) ? blend : max((1.0 - ((1.0 - base) / blend)), 0.0);
}

vec3 blendcolorburnb(vec3 base, vec3 blend) {
	return vec3(blendcolorburnf(base.r, blend.r), blendcolorburnf(base.g, blend.g), blendcolorburnf(base.b, blend.b));
}

vec3 blendcolorburn(vec3 base, vec3 blend, float opacity) {
	return (blendcolorburnb(base, blend) * opacity + base * (1.0 - opacity));
}


vec3 blenddifferenceb(vec3 base, vec3 blend) {
	return abs(base-blend);
}

vec3 blenddifference(vec3 base, vec3 blend, float opacity) {
	return (blenddifferenceb(base, blend) * opacity + base * (1.0 - opacity));
}


float blendscreenf(float base, float blend) {
	return 1.0 - ((1.0 - base) * (1.0 - blend));
}

vec3 blendscreenb(vec3 base, vec3 blend) {
	return vec3(blendscreenf(base.r, blend.r), blendscreenf(base.g, blend.g), blendscreenf(base.b, blend.b));
}

vec3 blendscreen(vec3 base, vec3 blend, float opacity) {
	return (blendscreenb(base, blend) * opacity + base * (1.0 - opacity));
}


vec3 blendnormalb(vec3 base, vec3 blend) {
	return blend;
}

vec3 blendnormal(vec3 base, vec3 blend, float opacity) {
	return (blendnormalb(base, blend) * opacity + base * (1.0 - opacity));
}


float blendsubtractf(float base, float blend) {
	return max(base + blend - 1.0, 0.0);
}

vec3 blendsubtractb(vec3 base, vec3 blend) {
	return max(base + blend - vec3(1.0), vec3(0.0));
}

vec3 blendsubtract(vec3 base, vec3 blend, float opacity) {
	return (blendsubtractb(base, blend) * opacity + base * (1.0 - opacity));
}


float blendlightenf(float base, float blend) {
	return max(blend, base);
}

vec3 blendlightenb(vec3 base, vec3 blend) {
	return vec3(blendlightenf(base.r, blend.r), blendlightenf(base.g, blend.g), blendlightenf(base.b, blend.b));
}

vec3 blendlighten(vec3 base, vec3 blend, float opacity) {
	return (blendlightenb(base, blend) * opacity + base * (1.0 - opacity));
}


float blendaddf(float base, float blend) {
	return min(base+blend, 1.0);
}

vec3 blendaddb(vec3 base, vec3 blend) {
	return min(base+blend, vec3(1.0));
}

vec3 blendadd(vec3 base, vec3 blend, float opacity) {
	return (blendaddb(base, blend) * opacity + base * (1.0 - opacity));
}


float blendsoftlightf(float base, float blend) {
	return (blend < 0.5) ? (2.0 * base * blend + base * base * (1.0 - 2.0 * blend)) : (sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base *(1.0 - blend));
}

vec3 blendsoftlightb(vec3 base, vec3 blend) {
	return vec3(blendsoftlightf(base.r, blend.r), blendsoftlightf(base.g, blend.g), blendsoftlightf(base.b, blend.b));
}

vec3 blendsoftlight(vec3 base, vec3 blend, float opacity) {
	return (blendsoftlightb(base, blend) * opacity + base * (1.0 - opacity));
}


float blendoverlayf(float base, float blend) {
	return base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend));
}

vec3 blendoverlayb(vec3 base, vec3 blend) {
	return vec3(blendoverlayf(base.r, blend.r), blendoverlayf(base.g, blend.g), blendoverlayf(base.b, blend.b));
}

vec3 blendoverlay(vec3 base, vec3 blend, float opacity) {
	return (blendoverlayb(base, blend) * opacity + base * (1.0 - opacity));
}
"""
