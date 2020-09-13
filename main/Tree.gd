extends Tree

var root : TreeItem
var tree_items : Dictionary = {}

signal texture_layer_added(layer, on_material_layer)

signal material_layer_selected(material_layer)
signal layer_texture_selected(layer_texture)
signal texture_layer_selected(texture_layer)

enum Buttons {
	MASK,
	RESULT,
	MAP_DROPDOWN,
	VISIBILITY,
}

const LayerMaterial = preload("res://material_layers/layer_material.gd")
const MaterialLayer = preload("res://material_layers/material_layer.gd")
const LayerTexture = preload("res://texture_layers/layer_texture.gd")
const TextureLayer = preload("res://texture_layers/texture_layer.gd")

onready var add_layer_popup_menu : PopupMenu = $AddLayerPopupMenu
onready var map_type_popup_menu : PopupMenu = $MapTypePopupMenu

func _ready() -> void:
	columns = 2
	set_column_expand(0, false)
	set_column_min_width(0, 100)


func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT and event.pressed:
		add_layer_popup_menu.rect_global_position = event.global_position
		add_layer_popup_menu.popup()


func setup_layer_material(layer_material : LayerMaterial) -> void:
	clear()
	root = create_item()
	for material_layer in layer_material.layers:
		add_material_layer(material_layer)


func add_material_layer(material_layer : MaterialLayer) -> void:
	var maps := material_layer.get_maps()
	var selected_map : LayerTexture = maps.values().front()
	
	var material_layer_item := create_item(root)
	material_layer_item.set_meta("layer", material_layer)
	material_layer_item.set_meta("selected", selected_map)
	if "mask" in material_layer.properties:
		material_layer_item.add_button(0, material_layer.properties.mask.result, Buttons.MASK)
	else:
		material_layer_item.set_selectable(0, false)
	material_layer_item.add_button(0, preload("res://layer.png"), Buttons.RESULT)
	if maps.size() > 1:
		material_layer_item.add_button(0, preload("res://down.svg"), Buttons.MAP_DROPDOWN)
	material_layer_item.set_text(1, "Material Layer")
	material_layer_item.add_button(1, preload("res://visibility.svg"), Buttons.VISIBILITY)
	
	tree_items[material_layer] = material_layer_item
	
	if selected_map:
		var selected_layer_texture : LayerTexture = material_layer.properties[material_layer_item.get_meta("selected")]
		for texture_layer in selected_layer_texture.layers:
			add_texture_layer(texture_layer, material_layer)


func add_texture_layer(texture_layer : TextureLayer, on_material_layer : MaterialLayer) -> void:
	var texture_layer_item := create_item(tree_items[on_material_layer])
	texture_layer_item.set_meta("layer", texture_layer)
	texture_layer_item.add_button(0, preload("res://layer.png"), Buttons.RESULT)
	texture_layer_item.set_text(1, "Texture Layer")
	texture_layer_item.add_button(1, preload("res://visibility.svg"), Buttons.VISIBILITY)
	tree_items[texture_layer] = texture_layer_item


func _on_button_pressed(item : TreeItem, column : int, id : int) -> void:
	match id:
		Buttons.MAP_DROPDOWN:
			map_type_popup_menu.rect_global_position = get_global_transform().xform(get_item_area_rect(item).position)
			map_type_popup_menu.popup()
		Buttons.RESULT:
			item.collapsed = not item.collapsed
			emit_signal("layer_texture_selected", item.get_meta("layer").properties[item.get_meta("selected")])
		Buttons.MASK:
			item.collapsed = not item.collapsed
			emit_signal("layer_texture_selected", item.get_meta("layer").properties.mask)
		Buttons.VISIBILITY:
			pass


func _on_AddLayerPopupMenu_id_pressed(id : int) -> void:
	var texture_layer := TextureLayer.new()
	var item := get_item_at_position(get_global_transform().xform_inv(add_layer_popup_menu.rect_position))
	var material_layer : MaterialLayer = item.get_meta("layer")
	var selected_map : String = item.get_meta("selected")
	var on_layer_texture : LayerTexture = material_layer.properties[selected_map]
	emit_signal("texture_layer_added", texture_layer, on_layer_texture)
	add_texture_layer(texture_layer, material_layer)


func _on_MapTypePopupMenu_id_pressed(id : int) -> void:
	var item := get_item_at_position(get_global_transform().xform_inv(add_layer_popup_menu.rect_position))
	item.set_meta("selected", map_type_popup_menu)


func _on_cell_selected() -> void:
	emit_signal("material_layer_selected", get_selected().get_meta("layer"))
