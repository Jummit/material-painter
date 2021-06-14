extends "texture_layer.gd"

var map_properties := {
	albedo = Properties.ColorProperty,
	emission = Properties.ColorProperty,
	height = Properties.FloatProperty,
	normal = Properties.ColorProperty,
	roughness = Properties.FloatProperty,
	metallic = Properties.FloatProperty,
	ao = Properties.FloatProperty,
}

const SHADERS := {
	TYPE_COLOR : "{value}",
	TYPE_REAL : "vec4({value})",
	TYPE_OBJECT : "texture({value}, uv)",
}

const Properties = preload("res://addons/property_panel/properties.gd")
const AssetProperty = preload("res://asset/asset_property/property_panel_property.gd")
const TextureAsset = preload("res://asset/assets/texture_asset.gd")
const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer

func _init(data := {}).(data) -> void:
	for map in enabled_maps:
		if settings.get(map + "_texture"):
			var image := load_png(settings[map + "_texture"])
			settings[map + "_texture"] = image
	for setting in settings:
		var value = settings[setting]
		if value is String:
			settings[setting] = str2var(value)


func load_png(path : String) -> ImageTexture:
	var image := Image.new()
	image.load(path)
	var texture := ImageTexture.new()
	texture.create_from_image(image)
	return texture


func serialize() -> Dictionary:
	var data := .serialize()
	for map in enabled_maps:
		if settings.get(map + "_texture"):
			var path : String = settings[map + "_texture"].path
			settings[map + "_texture"] = path
	return data


func get_type() -> String:
	return "fill"


func get_blending_layer(_context : MaterialGenerationContext,
		map : String) -> Layer:
	var value = settings.get(map)
	if settings.get(map + "_texture"):
		value = settings[map + "_texture"].texture
	if value == null:
		return null
	var layer := BlendingLayer.new(SHADERS[typeof(value)],
			blend_modes.get(map, "normal"), opacities.get(map, 1.0))
	layer.uniforms.value = value
	return layer


func get_properties() -> Array:
	var properties := []
	for map in enabled_maps:
		if not settings.get(map + "_texture"):
			# Show the grayscale/color property when no map is set.
			var property = map_properties[map]
			if property == Properties.FloatProperty:
				properties.append(property.new(map, 0, 1))
			else:
				properties.append(property.new(map))
		# Always show the texture property even if it isn't set.
		var asset_property := AssetProperty.new(map + "_texture", [TextureAsset])
		properties.append(asset_property)
	return properties
