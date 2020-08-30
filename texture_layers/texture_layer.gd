extends Resource

const Properties = preload("res://addons/property_panel/properties.gd")

# warning-ignore:unused_class_variable
export var name : String
export var properties : Dictionary
# warning-ignore:unused_class_variable
export var size := Vector2(1024, 1024)

var texture : Texture setget , get_texture

func get_properties() -> Array:
	return [
		Properties.FloatProperty.new("opacity", 0.0, 1.0),
		Properties.EnumProperty.new("blend_mode", Globals.BLEND_MODES)]


func get_texture():
	if not texture:
		generate_texture()
	return texture


func generate_texture():
	return null


func _init():
	properties = {
		opacity = 1.0,
		blend_mode = "normal"
	}
