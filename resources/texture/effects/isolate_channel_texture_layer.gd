extends "res://resources/texture/texture_layer.gd"

export var channel : String

const Properties = preload("res://addons/property_panel/properties.gd")

func _init().("isolate_channel", "Isolate Channel") -> void:
	pass


func get_properties() -> Array:
	return [
		Properties.EnumProperty.new("channel", ["r", "g", "b", "a"]),
	]


func _get_as_shader_layer() -> Layer:
	var layer := Layer.new()
	layer.code = "return {previous}(uv).%s%s%sa;" % [channel, channel, channel]
	return layer
