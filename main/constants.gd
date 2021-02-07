extends Node

"""
Global constants
"""

enum Tools {
	TRIANGLE,
	QUADS,
	MESH_ISLANDS,
	UV_ISLANDS,
	FLAT_SURFACE,
	PAINT,
}

const TEXTURE_MAP_TYPES := ["albedo", "emission", "height",
		"ao", "metallic", "roughness", "normal"]
const BLEND_MODES := ["normal", "add", "subtract", "multiply",
		"overlay", "screen", "darken", "lighten", "soft-light",
		"color-burn", "color-dodge"]
