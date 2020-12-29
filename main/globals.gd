extends Node

"""
Global constants
"""

# warning-ignore-all:unused_class_variable
var mesh : Mesh
var selected_tool : int = Tools.PAINT
var current_file : SaveFile setget set_current_file
var editing_layer_material : LayerMaterial setget set_editing_layer_material
var result_size := Vector2(2048, 2048)
var undo_redo := UndoRedo.new()

signal mesh_changed(mesh)
signal current_file_changed
signal editing_layer_material_changed

enum Tools {
	TRIANGLE,
	QUADS,
	MESH_ISLANDS,
	UV_ISLANDS,
	FLAT_SURFACE,
	PAINT,
}

var TEXTURE_LAYER_TYPES := [
	FileTextureLayer,
	BitmapTextureLayer,
	ColorTextureLayer,
	ScalarTextureLayer,
	BlurTextureLayer,
	HSVAdjustTextureLayer,
	IsolateColorTextureLayer,
	IsolateChannelTextureLayer,
	BrightnessContrastTextureLayer,
	InvertTextureLayer,
]

const BitmapTextureLayer = preload("res://resources/texture/layers/bitmap_texture_layer.gd")
const ColorTextureLayer = preload("res://resources/texture/layers/color_texture_layer.gd")
const ScalarTextureLayer = preload("res://resources/texture/layers/scalar_texture_layer.gd")
const FileTextureLayer = preload("res://resources/texture/layers/file_texture_layer.gd")
const BrightnessContrastTextureLayer = preload("res://resources/texture/effects/brightness_contrast_texture_layer.gd")
const IsolateChannelTextureLayer = preload("res://resources/texture/effects/isolate_channel_texture_layer.gd")

const BlurTextureLayer = preload("res://resources/texture/effects/blur_texture_layer.gd")
const HSVAdjustTextureLayer = preload("res://resources/texture/effects/hsv_adjust_texture_layer.gd")
const IsolateColorTextureLayer = preload("res://resources/texture/effects/isolate_color_texture_layer.gd")
const InvertTextureLayer = preload("res://resources/texture/effects/invert_texture_layer.gd")

const SaveFile = preload("res://resources/save_file.gd")
const LayerMaterial = preload("res://resources/material/layer_material.gd")
const ObjParser = preload("res://addons/obj_parser/obj_parser.gd")

const TEXTURE_MAP_TYPES := ["albedo", "emission", "height",
		"ao", "metallic", "roughness"]
const BLEND_MODES := ["normal", "add", "subtract", "multiply",
		"overlay", "screen", "darken", "lighten", "soft-light",
		"color-burn", "color-dodge"]

func load_model(path : String) -> void:
	mesh = ObjParser.parse_obj(path)
	current_file.model_path = path
	current_file.layer_materials.resize(mesh.get_surface_count())
	for surface in mesh.get_surface_count():
		if not current_file.layer_materials[surface]:
			current_file.layer_materials[surface] = LayerMaterial.new()
	current_file.layer_materials.front().update(true)
	set_editing_layer_material(current_file.layer_materials.front())
	emit_signal("mesh_changed", mesh)


func set_current_file(save_file : SaveFile) -> void:
	current_file = save_file
	load_model(current_file.model_path)
	for layer_material in current_file.layer_materials:
		var result = layer_material.update(true)
		if result is GDScriptFunctionState:
			yield(result, "completed")
	emit_signal("current_file_changed")


func set_editing_layer_material(to) -> void:
	editing_layer_material = to
	emit_signal("editing_layer_material_changed")
