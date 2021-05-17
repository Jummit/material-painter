extends "res://resources/texture/blending_texture_layer.gd"

"""
A texture layer that uses a loaded file to generate the result

The file is cached in `cached_image` to avoid loading it every shader update.
"""

var cached_path : String
var cached_image : Texture
var cached_triplanar_mapping : bool
var cached_scale : float

export var path := ""
export var triplanar_mapping := false
export var uv_scale := 1.0

const TextureUtils = preload("res://utils/texture_utils.gd")

func _init().("File", "texture({texture}, uv)") -> void:
	pass


func get_properties() -> Array:
	return .get_properties() + [
		Properties.FilePathProperty.new("path"),
		Properties.BoolProperty.new("triplanar_mapping"),
		Properties.FloatProperty.new("uv_scale", 0.0, 2.0),
		]


func _get_as_shader_layer(context : MaterialGenerationContext):
	var layer : BlendingLayer = ._get_as_shader_layer(context)
	layer.uniform_types.append("sampler2D")
	layer.uniform_names.append("texture")
	
	if cached_path != path or cached_triplanar_mapping != triplanar_mapping or\
			cached_scale != uv_scale:
		var dir := Directory.new()
		var global_path := path
		if path.begins_with("local://"):
			global_path = get_layer_material_in().root_folder.plus_file(path.trim_prefix("local://"))
		if not dir.file_exists(global_path):
			return layer
		var image := Image.new()
		image.load(global_path)
		cached_image = ImageTexture.new()
		cached_image.create_from_image(image)
		if triplanar_mapping:
			cached_image = TextureUtils.viewport_to_image(
					yield(context.triplanar_generator.get_triplanar_texture(
						cached_image, get_layer_material_in().mesh,
						context.result_size, Vector3.ONE * uv_scale),
						"completed"))
		cached_path = path
		cached_triplanar_mapping = triplanar_mapping
		cached_scale = uv_scale
	
	layer.uniform_values.append(cached_image)
	return layer
