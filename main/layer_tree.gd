extends Tree

"""
An interactive representation of a `LayerMaterial` as a tree

The tree consists of a list of `MaterialLayer`s with the `TextureLayer`s
of the selected `LayerTexture` below.
Shows previews of maps and masks as buttons.
"""

var root : TreeItem
var tree_items : Dictionary
var selected_maps : Dictionary
var selected_layer_textures : Dictionary
var expanded_folders : Array
var clicked_layer : MaterialLayer
var empty_texture := preload("res://main/loading_layer_icon.svg")
var last_edited : TreeItem

signal material_layer_selected(material_layer)
signal texture_layer_selected(texture_layer)
signal layer_visibility_changed(layer)

enum Buttons {
	MASK,
	RESULT,
	ICON,
	MAP_DROPDOWN,
	VISIBILITY,
}

enum LayerType {
	MATERIAL_LAYER,
	TEXTURE_LAYER,
}

const LayerMaterial = preload("res://layers/layer_material.gd")
const MaterialLayer = preload("res://layers/material_layer.gd")
const LayerTexture = preload("res://layers/layer_texture.gd")
const TextureLayer = preload("res://layers/texture_layer.gd")
const FileTextureLayer = preload("res://layers/texture_layers/file_texture_layer.gd")
const FolderLayer = preload("res://layers/folder_layer.gd")

onready var main : Control = $"../../../../.."
onready var material_layer_popup_menu : PopupMenu = $MaterialLayerPopupMenu
onready var map_type_popup_menu : PopupMenu = $MapTypePopupMenu

func _ready() -> void:
	set_column_expand(0, false)
	set_column_min_width(0, 100)


func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT and event.pressed:
		material_layer_popup_menu.rect_global_position = event.global_position
		var layer = get_item_at_position(event.position).get_meta("layer")
		if layer is MaterialLayer or get_material_layer_from_layer(layer):
			material_layer_popup_menu.layer = layer
			material_layer_popup_menu.layer_texture_selected = layer in selected_layer_textures or get_material_layer_from_layer(layer) in selected_layer_textures
			material_layer_popup_menu.popup()
	elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		if get_selected():
			get_selected().set_editable(1, true)
			if last_edited:
				last_edited.set_editable(1, false)
			last_edited = get_selected()


func get_drag_data(_position : Vector2):
	var selected_layers := []
	var selected = get_next_selected(null)
	var preview := VBoxContainer.new()
	var type = get_layer_type(selected)
	while selected:
		if get_layer_type(selected) == type:
			selected_layers.append(selected)
			var label = Label.new()
			label.text = selected.get_meta("layer").name
			preview.add_child(label)
		selected = get_next_selected(selected)
	set_drag_preview(preview)
	drop_mode_flags = DROP_MODE_INBETWEEN | DROP_MODE_ON_ITEM
	return {
		type = "layers",
		layers = selected_layers,
		layer_type = type,
	}


func can_drop_data(position : Vector2, data) -> bool:
	if data is Dictionary and "type" in data and data.type == "layers":
		var onto_layer = get_item_at_position(position).get_meta("layer")
		var layer_type : int = data.layer_type
		var is_folder := onto_layer is FolderLayer
		var onto_type : int = get_layer_type(get_item_at_position(position))
		if get_drop_section_at_position(position) == 0:
			return (layer_type == LayerType.TEXTURE_LAYER and onto_type == LayerType.MATERIAL_LAYER and not is_folder) or\
					(layer_type == onto_type and is_folder)
		else:
			return layer_type == onto_type
	return false


func drop_data(position : Vector2, data) -> void:
	var onto_layer = get_item_at_position(position).get_meta("layer")
	var layer_type : int = data.layer_type
	var is_folder := onto_layer is FolderLayer
	var onto_type : int = get_layer_type(get_item_at_position(position))
	match get_drop_section_at_position(position):
		0:
			var onto_array : Array
			if (layer_type == LayerType.TEXTURE_LAYER and onto_type == LayerType.MATERIAL_LAYER and not is_folder):
				onto_array = selected_layer_textures[onto_layer].layers
			elif LayerType.MATERIAL_LAYER == LayerType.MATERIAL_LAYER and is_folder:
				onto_array = onto_layer.layers
			for layer_item in data.layers:
				onto_array.append(layer_item.get_meta("layer").duplicate())
		var section:
			var onto_array := get_array_layer_is_in(onto_layer)
			var onto_position := onto_array.find(onto_layer)
			if section == 1:
				onto_position += 1
			onto_position = int(clamp(onto_position, 0, onto_array.size()))
			data.layers.invert()
			for layer_item in data.layers:
				onto_array.insert(onto_position, layer_item.get_meta("layer").duplicate())
	
	for layer_item in data.layers:
		get_array_layer_is_in(layer_item.get_meta("layer")).erase(layer_item.get_meta("layer"))
	setup_layer_material(main.editing_layer_material)
#	if data.asset is String:
#		var layer := FileTextureLayer.new()
#		layer.name = data.asset.get_file().get_basename()
#		layer.path = data.asset
#		main.add_texture_layer(layer, selected_layer_textures[get_item_at_position(position).get_meta("layer")].layers)
#	elif data.asset is MaterialLayer:
#		main.add_material_layer(data.asset)


func setup_layer_material(layer_material : LayerMaterial) -> void:
	tree_items = {}
	clear()
	root = create_item()
	for material_layer in layer_material.layers:
		setup_material_layer_item(material_layer, root)
	update_icons()


func setup_material_layer_item(material_layer, parent_item : TreeItem) -> void:
	var material_layer_item := create_item(parent_item)
	material_layer_item.set_meta("layer", material_layer)
	material_layer_item.custom_minimum_height = 32
	
	if material_layer is MaterialLayer:
		if not material_layer in selected_maps:
			if material_layer.maps.size() > 0:
				selected_maps[material_layer] = material_layer.maps.values().front()
		var selected_layer_texture : LayerTexture
		if material_layer in selected_layer_textures:
			selected_layer_texture = selected_layer_textures[material_layer]
		if selected_layer_texture:
			for texture_layer in selected_layer_texture.layers:
				setup_texture_layer_item(texture_layer, material_layer_item, selected_layer_texture)
		
		if material_layer.mask:
			material_layer_item.add_button(0, empty_texture, Buttons.MASK)
		if material_layer.maps.size() > 0:
			material_layer_item.add_button(0, empty_texture, Buttons.RESULT)
		if material_layer.maps.size() > 1:
			material_layer_item.add_button(0, preload("res://icons/down.svg"), Buttons.MAP_DROPDOWN)
	else:
		var icon : Texture = preload("res://icons/open_folder.svg") if material_layer in expanded_folders else preload("res://icons/large_folder.svg")
		material_layer_item.add_button(0, icon, Buttons.ICON)
	
	material_layer_item.set_text(1, material_layer.name)
	material_layer_item.add_button(1, empty_texture, Buttons.VISIBILITY)
	
	material_layer_item.set_custom_draw(0, self, "_draw_material_layer_item")
	material_layer_item.set_cell_mode(0, TreeItem.CELL_MODE_CUSTOM)
	
	tree_items[material_layer] = material_layer_item
	
	if material_layer is FolderLayer and material_layer in expanded_folders:
		for layer in material_layer.layers:
			setup_material_layer_item(layer, material_layer_item)


func setup_texture_layer_item(texture_layer, parent_item : TreeItem, layer_texture : LayerTexture) -> void:
	var texture_layer_item := create_item(parent_item)
	texture_layer_item.set_meta("layer", texture_layer)
	texture_layer_item.set_meta("layer_texture", layer_texture)
	texture_layer_item.custom_minimum_height = 32
	
	if texture_layer is TextureLayer:
		texture_layer_item.add_button(0, empty_texture, Buttons.RESULT)
	else:
		var icon : Texture = preload("res://icons/open_folder.svg") if texture_layer in expanded_folders else preload("res://icons/large_folder.svg")
		texture_layer_item.add_button(0, icon, Buttons.ICON)
	texture_layer_item.set_text(1, texture_layer.name)
	texture_layer_item.add_button(1, empty_texture, Buttons.VISIBILITY)
	tree_items[texture_layer] = texture_layer_item
	if texture_layer is FolderLayer and texture_layer in expanded_folders:
		for layer in texture_layer.layers:
			setup_texture_layer_item(layer, texture_layer_item, layer_texture)


func update_icons() -> void:
	for layer in tree_items:
		var tree_item : TreeItem = tree_items[layer]
		if layer is TextureLayer:
			tree_item.set_button(0, 0, yield(layer.generate_result(Vector2(32, 32), false), "completed"))
		elif layer is MaterialLayer:
			var button_count := 0
			if layer.mask:
				tree_item.set_button(0, 0, yield(layer.mask.generate_result(Vector2(32, 32), false), "completed"))
				button_count += 1
			if layer.maps.size() > 0:
				if layer in selected_maps:
					var selected_map : LayerTexture = selected_maps[layer]
					tree_item.set_button(0, button_count, yield(selected_map.generate_result(Vector2(32, 32), false), "completed"))
		tree_item.set_button(1, 0, preload("res://icons/icon_visible.svg") if layer.visible else preload("res://icons/icon_hidden.svg"))


func get_array_layer_is_in(layer) -> Array:
	var parent : TreeItem = tree_items[layer].get_parent()
	if parent == root:
		return main.editing_layer_material.layers
	else:
		var parent_layer = parent.get_meta("layer")
		if parent_layer is FolderLayer:
			return parent_layer.layers
		else:
			return selected_layer_textures[parent_layer].layers


func get_layer_type(layer_item : TreeItem) -> int:
	return LayerType.TEXTURE_LAYER if layer_item.has_meta("layer_texture") else LayerType.MATERIAL_LAYER


func get_selected_material_layer():
	return _get_selected_material_layer_item().get_meta("layer")


func get_selected_texture_layer() -> TextureLayer:
	return get_selected().get_meta("layer") as TextureLayer


func get_selected_layer_texture() -> LayerTexture:
	return selected_layer_textures[get_selected_material_layer()] as LayerTexture


func _get_selected_material_layer_item() -> TreeItem:
	if get_selected().get_meta("layer") is MaterialLayer or get_selected().get_meta("layer") is FolderLayer:
		return get_selected()
	return null


func get_material_layer_from_layer(layer) -> MaterialLayer:
	var parent_layer = tree_items[layer].get_parent().get_meta("layer")
	if not parent_layer:
		return null
	if parent_layer is MaterialLayer:
		return parent_layer
	else:
		return get_material_layer_from_layer(parent_layer)


func _on_button_pressed(item : TreeItem, _column : int, id : int) -> void:
	var layer = item.get_meta("layer")
	match id:
		Buttons.MAP_DROPDOWN:
			clicked_layer = layer
			map_type_popup_menu.rect_global_position = get_global_transform().xform(get_item_area_rect(item).position)
			map_type_popup_menu.popup()
		Buttons.RESULT:
			var material_layer : MaterialLayer = layer
			if material_layer in selected_layer_textures and selected_layer_textures[material_layer] == selected_maps[material_layer]:
				selected_layer_textures.erase(material_layer)
			else:
				selected_layer_textures[material_layer] = selected_maps[material_layer]
			setup_layer_material(main.editing_layer_material)
		Buttons.MASK:
			var material_layer : MaterialLayer = layer
			if material_layer in selected_layer_textures and selected_layer_textures[material_layer] == material_layer.mask:
				selected_layer_textures.erase(material_layer)
			else:
				selected_layer_textures[material_layer] = material_layer.mask
			setup_layer_material(main.editing_layer_material)
		Buttons.VISIBILITY:
			layer.visible = not layer.visible
			emit_signal("layer_visibility_changed", layer)
		Buttons.ICON:
			if layer in expanded_folders:
				expanded_folders.erase(layer)
			else:
				expanded_folders.append(layer)
			setup_layer_material(main.editing_layer_material)


func _on_MapTypePopupMenu_id_pressed(id : int) -> void:
	var selected_map : LayerTexture = clicked_layer.maps.values()[id]
	selected_maps[clicked_layer] = selected_map
	selected_layer_textures[clicked_layer] = selected_map
	update_icons()
	update()


func _on_cell_selected() -> void:
	var layer = get_selected().get_meta("layer")
	if layer is MaterialLayer:
		emit_signal("material_layer_selected", layer)
	elif layer is TextureLayer:
		emit_signal("texture_layer_selected", layer)


func _on_MapTypePopupMenu_about_to_show() -> void:
	map_type_popup_menu.clear()
	for map in clicked_layer.maps:
		map_type_popup_menu.add_item(map)
		var icon : ImageTexture = yield(
			clicked_layer.maps[map].generate_result(Vector2(32, 32), false), "completed")
		map_type_popup_menu.set_item_icon(map_type_popup_menu.get_item_count() - 1, icon)


func _draw_material_layer_item(material_layer_item : TreeItem, item_rect : Rect2) -> void:
	var material_layer = material_layer_item.get_meta("layer")
	if not material_layer is MaterialLayer:
		return
	if not material_layer in selected_layer_textures:
		return
	var selected : LayerTexture = selected_layer_textures[material_layer]
	var mask_pos := 25
	var map_pos := 68
	var icon_rect := Rect2(Vector2(
			mask_pos if selected == material_layer.mask else map_pos,
			3 + item_rect.position.y), Vector2(32, 32))
	if material_layer.maps.size() > 1:
		icon_rect.position.x -= 23
	draw_rect(icon_rect, Color.dodgerblue, false, 2.0)


func _on_item_edited() -> void:
	get_edited().get_meta("layer").name = get_edited().get_text(get_edited_column())
