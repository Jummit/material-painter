extends "res://arrangable_tree/arrangable_tree.gd"

onready var texture_layer_property_panel : Panel = $"../TextureLayerPropertyPanel"

const PropertyPanel = preload("res://property_panel/property_panel.gd")

class TextureLayer:
# warning-ignore:unused_class_variable
	var name : String
# warning-ignore:unused_class_variable
	var properties : Dictionary
	
	func get_properties() -> Array:
		return [PropertyPanel.EnumProperty.new("blend_mode", ["Normal", "Add", "Sub"])]
	
	func get_texture() -> Texture:
		return null

class ColorTextureLayer extends TextureLayer:
	func _init(_name : String):
		name = _name
		properties = {
			color = Color()
		}
	
	func get_properties() -> Array:
		return .get_properties() + [PropertyPanel.ColorProperty.new("color")]
	
	func get_texture() -> Texture:
		var image := Image.new()
		image.create(1028, 1028, false, Image.FORMAT_RGB8)
		image.fill(properties.color)
		var texture := ImageTexture.new()
		texture.create_from_image(image)
		return texture


class BitmapTextureLayer extends TextureLayer:
	func _init(_name : String):
		name = _name
		properties = {
			image_path = ""
		}
	
	func get_properties() -> Array:
		return .get_properties() + [PropertyPanel.FilePathProperty.new("image_path")]
	
	func get_texture() -> Texture:
		if ResourceLoader.exists(properties.image_path, "Texture"):
			var image := Image.new()
			if image.load(properties.image_path) == OK:
				var texture := ImageTexture.new()
				texture.create_from_image(image)
				return texture
		return null


class NoiseTextureLayer extends TextureLayer:
	func _init(_name : String):
		name = _name
		properties = {
			noise_seed = 0,
			octaves = 3,
			period = 64.0,
			persistence = 0.5,
			lacunarity = 2.0,
		}
	
	func get_properties() -> Array:
		return .get_properties() + [
				PropertyPanel.IntProperty.new("noise_seed", 0, 1000),
				PropertyPanel.IntProperty.new("octaves", 1, 9),
				PropertyPanel.FloatProperty.new("period", 0.1, 256.0),
				PropertyPanel.FloatProperty.new("persistence", 0.0, 1.0),
				PropertyPanel.FloatProperty.new("lacunarity", 0.1, 4.0),
			]
	
	func get_texture() -> Texture:
		var noise_texture := NoiseTexture.new()
		noise_texture.noise = OpenSimplexNoise.new()
		noise_texture.noise.seed = properties.noise_seed
		noise_texture.noise.octaves = properties.octaves
		noise_texture.noise.period = properties.period
		noise_texture.noise.persistence = properties.persistence
		noise_texture.noise.lacunarity = properties.lacunarity
		return noise_texture


func _on_TextureCreationDialog_texture_creation_confirmed(texture_layer : TextureLayer):
	layers.append(texture_layer)
	update_tree()


func _on_TextureLayerPropertyPanel_values_changed():
	get_selected().get_metadata(0).properties = texture_layer_property_panel.get_property_values()
	update_icons()


func update_tree():
	.update_tree()
	update_icons()


func update_icons() -> void:
	if not get_root():
		return
	var tree_item := get_root().get_children()
	while true:
		var texture_layer : TextureLayer = tree_item.get_metadata(0)
		var icon := texture_layer.get_texture()
		tree_item.set_icon(0, icon)
		tree_item.set_icon_max_width(0, 16)
		tree_item = tree_item.get_next_visible()
		if not tree_item:
			break


func _make_custom_tooltip(_for_text):
	var tooltip : PanelContainer = load("res://texture_tooltip/texture_tool_tip.tscn").instance()
	tooltip.call_deferred("setup", get_item_at_position(get_local_mouse_position()).get_metadata(0))
	return tooltip
