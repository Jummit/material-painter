extends ItemList

"""
A list of map results of the edited `LayerMaterial`
"""

signal map_selected(map)

const MaterialLayer = preload("res://material/material_layer.gd")
const LayerMaterial = preload("res://material/layer_material.gd")
const LayerTexture = preload("res://material/layer_texture.gd")
const TextureLayer = preload("res://material/texture_layer/texture_layer.gd")

func _gui_input(event : InputEvent) -> void:
	var button_ev := event as InputEventMouseButton
	if button_ev and button_ev.control:
		var size = fixed_icon_size.x
		if button_ev.button_index == BUTTON_WHEEL_UP:
			size += 5
		elif button_ev.button_index == BUTTON_WHEEL_DOWN:
			size -= 5
		fixed_icon_size = Vector2.ONE * max(size, 32)
		notification(NOTIFICATION_RESIZED)


func get_layout_data() -> float:
	return fixed_icon_size.x


func _on_item_activated(index : int) -> void:
	emit_signal("map_selected", get_item_metadata(index))


func _on_layout_changed(meta) -> void:
	if meta:
		fixed_icon_size = Vector2.ONE * meta


func _on_Main_current_layer_material_changed(to : LayerMaterial,
		_id : int) -> void:
	if not to.is_connected("results_changed", self,
			"_on_LayerMaterial_results_changed"):
		to.connect("results_changed", self,"_on_LayerMaterial_results_changed",
				[to])


func _on_LayerMaterial_results_changed(layer_material : LayerMaterial) -> void:
	clear()
	for map in layer_material.results:
		add_item(map, layer_material.results[map])
		set_item_metadata(get_item_count() - 1, map)
