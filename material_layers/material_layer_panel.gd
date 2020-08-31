extends VBoxContainer

onready var material_layer_property_panel : Panel = $MaterialLayerPropertyPanel
onready var model : MeshInstance = $"../VBoxContainer/3DViewport/Viewport/Model"
onready var material_layer_tree : Tree = $MaterialLayerTree
onready var main : Control = $"../../../.."

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


func set_editing_layer_material(to : LayerMaterial):
	editing_layer_material = to
	material_layer_tree.items = editing_layer_material.layers
	main.update_layer_material(editing_layer_material)
	material_layer_tree.update_tree()


func _on_MaterialLayerTree_item_selected():
	editing_material_layer = material_layer_tree.get_selected().get_metadata(0)
	
	material_layer_property_panel.build_properties(editing_material_layer)


func _on_MaterialLayerTree_nothing_selected():
	if not material_layer_tree.get_selected():
		editing_material_layer = null


func _on_MaterialLayerPropertyPanel_values_changed():
	editing_material_layer.properties = material_layer_property_panel.get_property_values()
	main.update_layer_material(editing_layer_material)


func _on_TextureChannelButtons_changed():
	material_layer_property_panel.build_properties(editing_material_layer)


func _on_AddMaterialLayerButton_pressed():
	editing_layer_material.layers.append(MaterialLayer.new())
	material_layer_tree.update_tree()
