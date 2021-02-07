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
	Constants.connect("current_layer_material_changed", self, "_on_Constants_current_layer_material_changed")


func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.control:
		var size = fixed_icon_size.x
		if event.button_index == BUTTON_WHEEL_UP:
			size += 5
		elif event.button_index == BUTTON_WHEEL_DOWN:
			size -= 5
		fixed_icon_size = Vector2.ONE * max(size, 32)
		get_parent().set_meta("layout", fixed_icon_size.x)
		notification(NOTIFICATION_RESIZED)


func _on_item_activated(index : int) -> void:
	emit_signal("map_selected", get_item_metadata(index))


func _on_Constants_current_layer_material_changed() -> void:
	if not Constants.current_layer_material.is_connected("results_changed", self,
			"_on_LayerMaterial_results_changed"):
		Constants.current_layer_material.connect("results_changed", self,
				"_on_LayerMaterial_results_changed")


func _on_LayerMaterial_results_changed() -> void:
	clear()
	for map in Constants.current_layer_material.results:
		add_item(map, Constants.current_layer_material.results[map])
		set_item_metadata(get_item_count() - 1, map)


func _on_layout_changed() -> void:
	if get_parent().has_meta("layout"):
		fixed_icon_size = Vector2.ONE * get_parent().get_meta("layout")
