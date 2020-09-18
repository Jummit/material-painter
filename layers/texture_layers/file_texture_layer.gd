extends "res://layers/texture_layer.gd"

var cashed_path : String
var cashed_image : Texture

export var path := ""

func _init(_name := "Untitled File Texture").("file"):
	name = _name


func get_properties() -> Array:
	return .get_properties() + [Properties.FilePathProperty.new("path")]


func _get_as_shader_layer() -> BlendingLayer:
	var layer := ._get_as_shader_layer()
	layer.code = "texture({0}, UV).rgb"
	layer.uniform_types = ["sampler2D"]
	
	if cashed_path != path:
		var image := Image.new()
		image.load(path)
		cashed_image = ImageTexture.new()
		cashed_image.create_from_image(image)
		cashed_path = path
	
	layer.uniform_values = [cashed_image]
	return layer
