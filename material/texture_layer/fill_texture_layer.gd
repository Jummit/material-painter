extends "texture_layer.gd"

var map_textures : Dictionary
var map_settings := {
	albedo = Color.white,
	emission = Color.white,
	height = 0.0,
	roughness = 1.0,
	metallic = 0.0,
	ao = 1.0,
}

var map_properties := {
	albedo = Properties.ColorProperty,
	emission = Properties.ColorProperty,
	height = Properties.FloatProperty,
	roughness = Properties.FloatProperty,
	metallic = Properties.FloatProperty,
	ao = Properties.FloatProperty,
}

const SHADERS := {
	TYPE_COLOR : "{value}",
	TYPE_REAL : "vec3({value})",
	TYPE_OBJECT : "texture({value}, uv)",
}

const Properties = preload("res://addons/property_panel/properties.gd")
const AssetProperty = preload("res://asset/asset_property/property_panel_property.gd")
const TextureAsset = preload("res://asset/assets/texture_asset.gd")
const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer

func _init(data := {}).(data) -> void:
	pass


func serialize() -> Dictionary:
	var data := .serialize()
	return data


func get_type() -> String:
	return "fill"


func get_blending_layer(_context : MaterialGenerationContext,
		map : String) -> Layer:
	var value = map_settings[map]
	if map in map_textures:
		value = map_textures[map]
	var layer := BlendingLayer.new(SHADERS[typeof(value)], blend_mode,
			opacity)
	layer.uniforms.value = value
	return layer


func get_properties() -> Array:
	var properties := []
	for map in enabled_maps:
		if not map in map_textures:
			# Show the grayscale/color property when no map is set.
			var property = map_properties[map]
			if property == Properties.FloatProperty:
				properties.append(property.new(map, 0, 1))
			else:
				properties.append(property.new(map))
		# Always show the texture property even if it isn't set.
		var asset_property := AssetProperty.new(map, [TextureAsset])
		properties.append(asset_property)
	return properties
