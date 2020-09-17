extends Tree

var root : TreeItem
var tree_items : Dictionary = {}

signal material_layer_selected(material_layer)
signal texture_layer_selected(texture_layer)

enum Buttons {
	MASK,
	RESULT,
	MAP_DROPDOWN,
	VISIBILITY,
}

const DEFAULT_RESULT = preload("res://icons/mask.png")

const LayerMaterial = preload("res://layers/layer_material.gd")
const MaterialLayer = preload("res://layers/material_layer.gd")
const LayerTexture = preload("res://layers/layer_texture.gd")
const TextureLayer = preload("res://layers/texture_layer.gd")
const BitmapTextureLayer = preload("res://layers/texture_layers/bitmap_texture_layer.gd")

onready var main : Control = $"../../../../.."
onready var material_layer_popup_menu : PopupMenu = $MaterialLayerPopupMenu
onready var map_type_popup_menu : PopupMenu = $MapTypePopupMenu

func _ready() -> void:
	columns = 2
	set_column_expand(0, false)
	set_column_min_width(0, 100)


func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT and event.pressed:
		material_layer_popup_menu.rect_global_position = event.global_position
		material_layer_popup_menu.popup()


func can_drop_data(_position : Vector2, data) -> bool:
	return data is Dictionary and "asset" in data


func drop_data(position : Vector2, data) -> void:
	if data.asset is String:
		var layer := BitmapTextureLayer.new()
		layer.properties.image_path = data.asset
		main.add_texture_layer(layer, get_item_at_position(position).get_meta("layer").properties[get_item_at_position(position).get_meta("selected")])
	elif data.asset is MaterialLayer:
		main.add_material_layer(data.asset)


func setup_layer_material(layer_material : LayerMaterial) -> void:
	clear()
	root = create_item()
	for material_layer in layer_material.layers:
		setup_material_layer_item(material_layer)


func setup_material_layer_item(material_layer : MaterialLayer) -> void:
	var material_layer_item := create_item(root)
	material_layer_item.set_meta("layer", material_layer)
	
	var maps := material_layer.get_maps()
	var selected_map : LayerTexture
	if maps.size() > 0:
		selected_map = maps.values().front()
		material_layer_item.set_meta("selected", maps.keys().front())
	
	if "mask" in material_layer.properties:
		material_layer_item.add_button(0, material_layer.properties.mask.result, Buttons.MASK)
	if maps.size() > 0:
		material_layer_item.add_button(0, DEFAULT_RESULT, Buttons.RESULT)
	if maps.size() > 1:
		material_layer_item.add_button(0, preload("res://icons/down.svg"), Buttons.MAP_DROPDOWN)
	
	material_layer_item.set_text(1, material_layer.name)
	material_layer_item.add_button(1, preload("res://icons/visibility.svg"), Buttons.VISIBILITY)
	tree_items[material_layer] = material_layer_item
	
	if selected_map:
		var selected_layer_texture : LayerTexture = material_layer.properties[material_layer_item.get_meta("selected")]
		for texture_layer in selected_layer_texture.layers:
			setup_texture_layer_item(texture_layer, material_layer_item)


func setup_texture_layer_item(texture_layer : TextureLayer, on_item : TreeItem) -> void:
	var texture_layer_item := create_item(on_item)
	texture_layer_item.set_meta("layer", texture_layer)
	texture_layer_item.add_button(0, DEFAULT_RESULT, Buttons.RESULT)
	texture_layer_item.set_text(1, "Texture Layer")
	texture_layer_item.add_button(1, preload("res://icons/visibility.svg"), Buttons.VISIBILITY)
	tree_items[texture_layer] = texture_layer_item


func update_icons() -> void:
	pass
#	for layer in tree_items.keys():
#		var tree_item : TreeItem = tree_items[layer]
#		if layer is TextureLayer:
#			tree_item.set_button(0, 0, layer.result)


func get_selected_material_layer() -> MaterialLayer:
	return _get_selected_material_layer_item().get_meta("layer")


func get_selected_texture_layer() -> TextureLayer:
	return get_selected().get_meta("layer") as TextureLayer


func get_selected_layer_texture() -> LayerTexture:
	return get_selected_material_layer().properties[\
			_get_selected_material_layer_item().get_meta("selected")] as LayerTexture


func _get_selected_material_layer_item() -> TreeItem:
	if get_selected().get_meta("layer") is MaterialLayer:
		return get_selected()
	else:
		return get_selected().get_parent()


func _on_button_pressed(item : TreeItem, _column : int, id : int) -> void:
	match id:
		Buttons.MAP_DROPDOWN:
			map_type_popup_menu.rect_global_position = get_global_transform().xform(get_item_area_rect(item).position)
			map_type_popup_menu.popup()
		Buttons.RESULT:
			item.collapsed = not item.collapsed
		Buttons.MASK:
			item.collapsed = not item.collapsed
			emit_signal("layer_texture_selected", item.get_meta("layer").properties.mask)
		Buttons.VISIBILITY:
			pass


func _on_MapTypePopupMenu_id_pressed(_id : int) -> void:
	var item := get_item_at_position(get_global_transform().xform_inv(material_layer_popup_menu.rect_position))
	item.set_meta("selected", map_type_popup_menu)


func _on_cell_selected() -> void:
	var layer = get_selected().get_meta("layer")
	if layer is MaterialLayer:
		emit_signal("material_layer_selected", layer)
	elif layer is TextureLayer:
		emit_signal("texture_layer_selected", layer)
