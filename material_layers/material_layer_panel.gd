extends VBoxContainer

onready var material_layer_property_panel : Panel = $MaterialLayerPropertyPanel
onready var texture_layer_panel : VBoxContainer = $"../TextureLayerPanel"
onready var model : MeshInstance = $"../VBoxContainer/3DViewport/Viewport/Model"
onready var blending_viewport : Viewport = $"../../../../MaskedTextureBlendingViewport"
onready var material_layer_tree : Tree = $MaterialLayerTree

const MaterialLayer = preload("res://material_layers/material_layer.gd")
const LayerMaterial = preload("res://material_layers/layer_material.gd")
const LayerTexture = preload("res://texture_layers/layer_texture.gd")

var editing_layer_material : LayerMaterial = LayerMaterial.new() setget set_editing_layer_material
var editing_material_layer : MaterialLayer

func _ready():
	material_layer_tree.items = editing_layer_material.layers


func _input(event):
	if event.is_action_pressed("save"):
		for type in Globals.TEXTURE_MAP_TYPES:
			var t = model.get_surface_material(0).get(type + "_texture")
			if t:
				t.get_data().save_png("res://export/%s.png" % type)


func update_result() -> void:
	for type in Globals.TEXTURE_MAP_TYPES:
		update_channel(type)


func update_channel(type : String) -> void:
	var textures := []
	var options := []
	for layer in editing_layer_material.layers:
		layer = layer as MaterialLayer
		if layer.properties.has(type) and layer.properties[type] and layer.properties[type].result and layer.properties.mask:
			textures.append(layer.properties[type].result)
			options.append({
				mask = layer.properties.mask.result
			})
	
	if not textures.empty():
		var result : ImageTexture = yield(blending_viewport.blend(textures, options), "completed")
		model.get_surface_material(0).set(type + "_texture", result)


func set_editing_layer_material(to : LayerMaterial):
	editing_layer_material = to
	update_result()
	material_layer_tree.update_tree()


func _on_MaterialLayerTree_item_selected():
	editing_material_layer = material_layer_tree.get_selected().get_metadata(0)
	
	material_layer_property_panel.build_properties(editing_material_layer)


func _on_MaterialLayerTree_nothing_selected():
	release_focus()
	editing_material_layer = null


func _on_MaterialLayerPropertyPanel_values_changed():
	editing_material_layer.properties = material_layer_property_panel.get_property_values()
	update_result()


func _on_TextureChannelButtons_changed():
	material_layer_property_panel.build_properties(editing_material_layer)


func _on_AddMaterialLayerButton_pressed():
	editing_layer_material.layers.append(MaterialLayer.new())
	material_layer_tree.update_tree()


func _on_TextureLayerPropertyPanel_values_changed():
	var editing_layer_texture : LayerTexture = texture_layer_panel.editing_layer_texture
	for layer in editing_layer_material.layers:
		layer = layer as MaterialLayer
		for channel in layer.properties.keys():
			if channel in Globals.TEXTURE_MAP_TYPES:
				if layer.properties[channel] is LayerTexture and layer.properties[channel] == editing_layer_texture:
					update_channel(channel)
