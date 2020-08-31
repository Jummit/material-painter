extends VBoxContainer

onready var texture_layer_property_panel : Panel = $TextureLayerPropertyPanel
onready var texture_blending_viewport : Viewport = $"../../../../TextureBlendingViewport"
onready var texture_layer_tree : Tree = $TextureLayerTree
onready var main : Control = $"../../../.."

const TextureLayer = preload("res://texture_layers/texture_layer.gd")
const TextureOption = preload("res://texture_option/texture_option.gd")
const LayerTexture = preload("res://texture_layers/layer_texture.gd")

var editing_layer_texture : LayerTexture
var editing_texture_layer : TextureLayer

func _ready():
	get_tree().connect("node_added", self, "_on_SceneTree_node_added")


#func load_layer_texture(layer_texture : LayerTexture) -> void:
func load_layer_texture(layer_texture) -> void:
	editing_layer_texture = layer_texture
	texture_layer_tree.items = layer_texture.layers
	texture_layer_tree.update_tree()
	texture_layer_tree.update_icons()


func _on_TextureLayerTree_item_selected():
	editing_texture_layer = texture_layer_tree.get_selected().get_metadata(0)
	
	texture_layer_property_panel.properties = editing_texture_layer.get_properties()
	texture_layer_property_panel.load_values(editing_texture_layer.properties)


func _on_TextureLayerTree_nothing_selected():
	if not texture_layer_tree.get_selected():
		editing_texture_layer = null


func _on_TextureCreationDialog_texture_creation_confirmed(texture_layer : TextureLayer):
	editing_layer_texture.layers.append(texture_layer)
	texture_layer_tree.update_tree()
	texture_layer_tree.update_icons()
	update_layer_texture_result(editing_layer_texture)


func _on_TextureLayerPropertyPanel_values_changed():
	editing_texture_layer.properties = texture_layer_property_panel.get_property_values()
	editing_texture_layer.generate_texture()
	texture_layer_tree.update_icons()
	update_layer_texture_result(editing_layer_texture)


func _on_TextureOption_selected(texture_option : TextureOption):
	load_layer_texture(texture_option.selected_texture)
	texture_layer_tree.update_tree()
	texture_layer_tree.update_icons()


func _on_SceneTree_node_added(node : Node):
	if node is TextureOption:
		node.connect("selected", self, "_on_TextureOption_selected", [node])


func update_layer_texture_result(layer_texture : LayerTexture) -> void:
	var textures := []
	var options := []
	
	for layer in layer_texture.layers:
		layer = layer as TextureLayer
		textures.append(layer.texture)
		options.append({
			blend_mode = layer.properties.blend_mode,
			opacity = layer.properties.opacity,
		})
	
	var result : Texture = yield(texture_blending_viewport.blend(textures, options), "completed")
	layer_texture.result = result
	# todo: only update correct channel
	main.update_layer_material($"../MaterialLayerPanel".editing_layer_material)
