extends ItemList

"""
A list of map results of the edited `LayerMaterial`
"""

signal map_selected(map)

const MaterialLayer = preload("res://resources/material/material_layer.gd")
const LayerMaterial = preload("res://resources/material/layer_material.gd")
const LayerTexture = preload("res://resources/texture/layer_texture.gd")
const TextureLayer = preload("res://resources/texture/texture_layer.gd")

func _ready():
	Globals.connect("editing_layer_material_changed", self, "_on_Globals_editing_layer_material_changed")


func _on_item_activated(index : int) -> void:
	emit_signal("map_selected", get_item_metadata(index))


func _on_Globals_editing_layer_material_changed() -> void:
	if not Globals.editing_layer_material.is_connected("results_changed", self,
			"_on_LayerMaterial_results_changed"):
		Globals.editing_layer_material.connect("results_changed", self,
				"_on_LayerMaterial_results_changed")


func _on_LayerMaterial_results_changed() -> void:
	clear()
	for map in Globals.editing_layer_material.results:
		add_item(map, Globals.editing_layer_material.results[map])
		set_item_metadata(get_item_count() - 1, map)
