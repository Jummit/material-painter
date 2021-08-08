extends Reference

"""
The brush representation used in the editor and in `BrushAsset`s

Can be saved to file and converted to a `Painter` brush.
"""

var size : float
var strength : float
var pattern_scale : float
var texture_angle : float
var stamp_mode : bool
var material : MaterialLayerStack

const MaterialLayerStack = preload("res://material/material_layer_stack.gd")
const PainterBrush = preload("res://addons/painter/brush.gd")

func _init(data := {}) -> void:
	size = data.get("size", 10.0)
	strength = data.get("strength", 0.5)
	pattern_scale = data.get("pattern_scale", 1.0)
	texture_angle = data.get("texture_angle", 0.0)
	stamp_mode = data.get("stamp_mode", false)
	material = MaterialLayerStack.new(data.get("material", []))


func serialize() -> Dictionary:
	return {
		size = size,
		strength = strength,
		pattern_scale = pattern_scale,
		texture_angle = texture_angle,
		stamp_mode = stamp_mode,
		material = material.serialize()
	}


func get_painter_brush(map : String) -> PainterBrush:
	var brush := PainterBrush.new()
	brush.size = size
	brush.strength = strength
	brush.pattern_scale = pattern_scale
	brush.texture_angle = texture_angle
	brush.stamp_mode = stamp_mode
	brush.texture = material.results.get(map)
	return brush
