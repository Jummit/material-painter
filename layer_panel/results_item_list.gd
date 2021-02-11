extends ItemList

"""
A list of map results of the edited `LayerMaterial`
"""

signal map_selected(map)

const MaterialLayer = preload("res://resources/material/material_layer.gd")
const LayerMaterial = preload("res://resources/material/layer_material.gd")
const LayerTexture = preload("res://resources/texture/layer_texture.gd")
const TextureLayer = preload("res://resources/texture/texture_layer.gd")

func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.control:
		var size = fixed_icon_size.x
		if event.button_index == BUTTON_WHEEL_UP:
			size += 5
		elif event.button_index == BUTTON_WHEEL_DOWN:
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


func _on_Main_current_layer_material_changed(to : LayerMaterial) -> void:
	if not to.is_connected("changed", self, "_on_LayerMaterial_changed"):
		to.connect("changed", self, "_on_LayerMaterial_changed", [to])


func _on_LayerMaterial_changed(layer_material : LayerMaterial) -> void:
	clear()
	for map in layer_material.results:
		add_item(map, layer_material.results[map])
		set_item_metadata(get_item_count() - 1, map)
