extends "res://addons/arrangable_tree/arrangable_tree.gd"

onready var material_layer_property_panel : Panel = $"../MaterialLayerPropertyPanel"
onready var texture_blending_viewport : Viewport = $"../../../TextureBlendingViewport"
onready var model : MeshInstance = $"../../3DViewport/Viewport/Model"

const MaterialLayer = preload("res://material_layers/material_layer.gd")
const LayerTexture = preload("res://texture_layers/layer_texture.gd")

func setup_item(layer_item : TreeItem, layer : MaterialLayer) -> void:
	layer_item.set_text(0, layer.name)
	layer_item.set_editable(0, true)


func update_result() -> void:
	var material_layer : MaterialLayer = get_selected().get_metadata(0)
	var properties : Dictionary = material_layer_property_panel.get_property_values()
	material_layer.properties = properties
	
	for type in Globals.TEXTURE_MAP_TYPES:
		var map_layers = []
		for layer in layers:
			layer = layer as MaterialLayer
			if layer.properties.has(type) and layer.properties[type] and layer.properties[type].result:
				map_layers.append(layer.properties[type].result)
		if not map_layers.empty():
			var result : ImageTexture = yield(texture_blending_viewport.blend(map_layers, [], [], "overlay", .5), "completed")
			model.get_surface_material(0).albedo_texture = result


func _on_AddMaterialLayerButton_pressed():
	var new_layer := MaterialLayer.new()
	layers.append(new_layer)
	update_tree()


func _on_item_edited():
	get_selected().get_metadata(0).name = get_selected().get_text(0)


func _on_MaterialLayerPropertyPanel_values_changed():
	get_selected().get_metadata(0).properties = material_layer_property_panel.get_property_values()
#	update_result()


func _on_TextureLayerPropertyPanel_values_changed():
	update_result()
