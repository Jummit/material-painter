extends Node

"""
Global constants
"""

const BitmapTextureLayer = preload("res://resources/texture_layers/bitmap_texture_layer.gd")
const ColorTextureLayer = preload("res://resources/texture_layers/color_texture_layer.gd")
const ScalarTextureLayer = preload("res://resources/texture_layers/scalar_texture_layer.gd")
const FileTextureLayer = preload("res://resources/texture_layers/file_texture_layer.gd")
const BrightnessContrastTextureLayer = preload("res://resources/effects/brightness_contrast_texture_layer.gd")

const BlurTextureLayer = preload("res://resources/effects/blur_texture_layer.gd")
const HSVAdjustTextureLayer = preload("res://resources/effects/hsv_adjust_texture_layer.gd")
const IsolateColorTextureLayer = preload("res://resources/effects/isolate_color_texture_layer.gd")

const TEXTURE_MAP_TYPES := ["albedo", "emission", "height",
		"ao", "metallic", "roughness"]
const BLEND_MODES := ["normal", "add", "subtract", "multiply",
		"overlay", "screen", "darken", "lighten", "soft-light",
		"color-burn", "color-dodge"]
# warning-ignore:unused_class_variable
var TEXTURE_LAYER_TYPES := [
	FileTextureLayer,
	BitmapTextureLayer,
	ColorTextureLayer,
	ScalarTextureLayer,
	BlurTextureLayer,
	HSVAdjustTextureLayer,
	IsolateColorTextureLayer,
	BrightnessContrastTextureLayer,
]

# warning-ignore:unused_class_variable
var mesh : Mesh
