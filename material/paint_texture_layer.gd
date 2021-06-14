extends "texture_layer.gd"

# warning-ignore:unused_class_variable
var paint_textures : Dictionary

const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer

func _init(data := {}).(data) -> void:
	pass


func get_blending_layer(_context : MaterialGenerationContext,
		map : String) -> Layer:
	if not map in paint_textures:
		return null
	var layer := BlendingLayer.new("texture(uv, {map})",
			blend_modes.get(map, "normal"), opacities.get(map, 1.0))
	layer.uniforms.map = paint_textures[map]
	return layer


func serialize() -> Dictionary:
	var data := .serialize()
	return data


func get_type() -> String:
	return "paint"
