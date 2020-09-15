extends Node

const BitmapTextureLayer = preload("res://texture_layers/types/bitmap_texture_layer.gd")
const ColorTextureLayer = preload("res://texture_layers/types/color_texture_layer.gd")
const ScalarTextureLayer = preload("res://texture_layers/types/scalar_texture_layer.gd")
const NoiseTextureLayer = preload("res://texture_layers/types/noise_texture_layer.gd")

const TEXTURE_MAP_TYPES := ["albedo", "emission", "height",
		"ao", "metalic", "roughness"]
const BLEND_MODES := ["normal", "add", "subtract", "multiply",
		"overlay", "screen", "darken", "lighten", "soft-light",
		"color-burn", "color-dodge"]
# warning-ignore:unused_class_variable
var TEXTURE_LAYER_TYPES := [
	BitmapTextureLayer,
	ColorTextureLayer,
	ScalarTextureLayer,
	NoiseTextureLayer
]
