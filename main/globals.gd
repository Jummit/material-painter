extends Node

"""
Global constants
"""

const BitmapTextureLayer = preload("res://resources/texture/layers/bitmap_texture_layer.gd")
const ColorTextureLayer = preload("res://resources/texture/layers/color_texture_layer.gd")
const ScalarTextureLayer = preload("res://resources/texture/layers/scalar_texture_layer.gd")
const FileTextureLayer = preload("res://resources/texture/layers/file_texture_layer.gd")
const BrightnessContrastTextureLayer = preload("res://resources/texture/effects/brightness_contrast_texture_layer.gd")

const BlurTextureLayer = preload("res://resources/texture/effects/blur_texture_layer.gd")
const HSVAdjustTextureLayer = preload("res://resources/texture/effects/hsv_adjust_texture_layer.gd")
const IsolateColorTextureLayer = preload("res://resources/texture/effects/isolate_color_texture_layer.gd")
const InvertTextureLayer = preload("res://resources/texture/effects/invert_texture_layer.gd")

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
	InvertTextureLayer,
]

# warning-ignore:unused_class_variable
var mesh : Mesh
