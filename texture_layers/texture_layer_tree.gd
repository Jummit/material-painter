extends "res://addons/arrangable_tree/arrangable_tree.gd"

onready var texture_layer_property_panel : Panel = $"../TextureLayerPropertyPanel"

const PropertyPanel = preload("res://addons/property_panel/property_panel.gd")

const ICON_COLUMN := 0
const NAME_COLUMN := 1

class TextureLayer:
# warning-ignore:unused_class_variable
	var name : String
# warning-ignore:unused_class_variable
	var properties : Dictionary
	var texture : Texture
	
	func get_properties() -> Array:
		return [PropertyPanel.EnumProperty.new("blend_mode", ["Normal", "Add", "Sub"])]
	
	func generate_texture():
		return null

class ColorTextureLayer extends TextureLayer:
	func _init(_name : String):
		name = _name
		properties = {
			color = Color()
		}
	
	func get_properties() -> Array:
		return .get_properties() + [PropertyPanel.ColorProperty.new("color")]
	
	func generate_texture():
		var image := Image.new()
		image.create(1028, 1028, false, Image.FORMAT_RGB8)
		image.fill(properties.color)
		texture = ImageTexture.new()
		texture.create_from_image(image)


class BitmapTextureLayer extends TextureLayer:
	func _init(_name : String):
		name = _name
		properties = {
			image_path = ""
		}
	
	func get_properties() -> Array:
		return .get_properties() + [PropertyPanel.FilePathProperty.new("image_path")]
	
	func generate_texture():
		if ResourceLoader.exists(properties.image_path, "Texture"):
			var image := Image.new()
			if image.load(properties.image_path) == OK:
				texture = ImageTexture.new()
				texture.create_from_image(image)


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
	
	func generate_texture():
		var noise := OpenSimplexNoise.new()
		noise.seed = properties.noise_seed
		noise.octaves = properties.octaves
		noise.period = properties.period
		noise.persistence = properties.persistence
		noise.lacunarity = properties.lacunarity
		texture = NoiseTexture.new()
		texture.noise = noise


func _ready():
	columns = 2
	set_column_expand(ICON_COLUMN, false)
	set_column_min_width(ICON_COLUMN, 32)


func _on_TextureCreationDialog_texture_creation_confirmed(texture_layer : TextureLayer):
	layers.append(texture_layer)
	texture_layer.generate_texture()
	update_tree()


func _on_TextureLayerPropertyPanel_values_changed():
	get_selected().get_metadata(0).properties = texture_layer_property_panel.get_property_values()
	get_selected().get_metadata(0).generate_texture()
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
		var icon := texture_layer.texture
		tree_item.set_icon(ICON_COLUMN, icon)
		tree_item.set_icon_max_width(ICON_COLUMN, 16)
		tree_item = tree_item.get_next_visible()
		if not tree_item:
			break


func _make_custom_tooltip(_for_text : String):
	var tooltip : PanelContainer = load("res://texture_layers/texture_tooltip/texture_tool_tip.tscn").instance()
	tooltip.call_deferred("setup", get_item_at_position(get_local_mouse_position()).get_metadata(0))
	return tooltip


func setup_item(layer_item : TreeItem, layer) -> void:
	layer_item.set_text(NAME_COLUMN, layer.name)
	layer_item.set_editable(NAME_COLUMN, true)


func _on_item_edited():
	get_selected().get_metadata(0).name = get_selected().get_text(NAME_COLUMN)
