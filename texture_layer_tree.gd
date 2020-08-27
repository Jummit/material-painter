extends "res://Tree.gd"

onready var texture_layer_property_panel : Panel = $"../TextureLayerPropertyPanel"

const PropertyPanel = preload("res://property_panel/property_panel.gd")

class TextureLayer:
	var name : String
	var properties : Dictionary
	
	func get_properties() -> Array:
		return []
	
	func get_texture() -> Texture:
		return Texture.new()

class ColorTextureLayer extends TextureLayer:
	func _init(_name : String):
		name = _name
	
	func get_properties() -> Array:
		return [PropertyPanel.ColorProperty.new("color")]
	
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
	
	func get_properties() -> Array:
		return [PropertyPanel.FilePathProperty.new("image_path")]
	
	func get_texture() -> Texture:
		var image := Image.new()
		image.load(properties.image_path)
		var texture := ImageTexture.new()
		texture.create_from_image(image)
		return texture


func _on_TextureCreationDialog_texture_creation_confirmed(texture_layer : TextureLayer):
	layers.append(texture_layer)
	update_tree()


func _on_TextureLayerPropertyPanel_values_changed():
	get_selected().get_metadata(0).properties = texture_layer_property_panel.get_property_values()
	if not get_root():
		return
	var tree_item := get_root().get_children()
	while true:
		var texture_layer : TextureLayer = tree_item.get_metadata(0)
		var icon := texture_layer.get_texture()
		tree_item.set_icon(0, icon)
		tree_item.set_icon_max_width(0, 10)
		tree_item = tree_item.get_next_visible()
		if not tree_item:
			break
