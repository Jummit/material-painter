extends "texture_layer.gd"

"""
A texture layer that fills the channels with a solid color, value or texture
"""

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
	TYPE_REAL : "vec4(vec3({value}), 1.0)",
	TYPE_OBJECT : "texture({value}, uv)",
}

const DEFAULTS := {
	metallic = 0,
	roughness = 1,
}

const Properties = preload("res://addons/property_panel/properties.gd")
const AssetProperty = preload("res://asset/asset_property/panel_asset_property.gd")
const TextureAsset = preload("res://asset/assets/texture_asset.gd")
const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer

func _init(data := {}).(data) -> void:
	for setting in settings:
		var value = settings[setting]
		if value is String and value.begins_with("Color("):
			settings[setting] = str2var(value)
		elif value is String:
			settings[setting] = TextureAsset.new(value)


func serialize() -> Dictionary:
	var data := .serialize()
	for setting in settings:
		var value = settings[setting]
		if value is TextureAsset:
			settings[setting] = value.path
		elif value is Color:
			settings[setting] = var2str(value)
	return data


func get_type() -> String:
	return "fill"


func get_blending_layer(context : MaterialGenerationContext,
		map : String) -> Layer:
	var value = get_map_value(map)
	if value == null:
		return null
	elif value is Texture and settings.get(map + "/triplanar"):
		value = yield(context.triplanar_generator.get_triplanar_texture(value,
				context.mesh, context.result_size), "completed")
	var layer := BlendingLayer.new(SHADERS[typeof(value)],
			blend_modes.get(map, "normal"), opacities.get(map, 1.0))
	layer.uniforms.value = value
	return layer


func get_map_value(map : String):
	var texture = settings.get(map + "/texture")
	if texture:
		return texture.texture
	return settings.get(map + "/value")


func get_properties() -> Array:
	var properties := []
	for map in enabled_maps:
		if not get_map_value(map) is ImageTexture:
			# Show the grayscale/color property when no map is set.
			var property = map_properties[map]
			if property == Properties.FloatProperty:
				properties.append(property.new(map + "/value", 0, 1,
						DEFAULTS.get(map, 0)))
			else:
				properties.append(property.new(map + "/value"))
		# Always show the texture property even if it isn't set.
		var asset_property := AssetProperty.new(map + "/texture", [TextureAsset])
		properties.append(asset_property)
		properties.append(Properties.BoolProperty.new(map + "/triplanar"))
	return properties


func set_property(property : String, value) -> void:
	if property.ends_with("/texture") and typeof(value) != typeof(
				settings.get(property)):
		mark_dirty(true)
	settings[property] = value
