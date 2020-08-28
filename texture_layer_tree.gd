extends "res://Tree.gd"

onready var texture_layer_property_panel : Panel = $"../TextureLayerPropertyPanel"

const PropertyPanel = preload("res://property_panel/property_panel.gd")

class TextureLayer:
# warning-ignore:unused_class_variable
	var name : String
# warning-ignore:unused_class_variable
	var properties : Dictionary
	var blend_mode : int
	
	func get_properties() -> Array:
		return []
	
	func get_texture() -> Texture:
		return null

class ColorTextureLayer extends TextureLayer:
	func _init(_name : String):
		name = _name
		properties = {
			color = Color()
		}
	
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
		properties = {
			image_path = ""
		}
	
	func get_properties() -> Array:
		return [PropertyPanel.FilePathProperty.new("image_path")]
	
	func get_texture() -> Texture:
		if ResourceLoader.exists(properties.image_path, "Texture"):
			var image := Image.new()
			if image.load(properties.image_path) == OK:
				var texture := ImageTexture.new()
				texture.create_from_image(image)
				return texture
		return null


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
