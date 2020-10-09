extends Tree

"""
An interactive representation of a `LayerMaterial` as a tree

The tree consists of a list of `MaterialLayer`s with the `TextureLayer`s
of the selected `LayerTexture` below.
Shows previews of maps and masks as buttons.
"""

var editing_layer_material : LayerMaterial setget set_editing_layer_material

var _root : TreeItem
var _lastly_edited_layer : TreeItem
var _empty_texture := preload("res://icons/loading_layer.svg")
var _small_empty_texture := preload("res://icons/small_loading_layer.svg")
var _tree_items : Dictionary
var _selected_layer_textures : Dictionary
var _selected_maps : Dictionary
var _expanded_folders : Array

signal material_layer_selected(material_layer)
signal texture_layer_selected(texture_layer)
signal folder_layer_selected
# warning-ignore:unused_signal
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

const LayerMaterial = preload("res://resources/layer_material.gd")
const MaterialLayer = preload("res://resources/material_layer.gd")
const LayerTexture = preload("res://resources/layer_texture.gd")
const TextureLayer = preload("res://resources/texture_layer.gd")
const FileTextureLayer = preload("res://resources/texture_layers/file_texture_layer.gd")
const FolderLayer = preload("res://resources/folder_layer.gd")

onready var main : Control = $"../../../../.."
onready var undo_redo : UndoRedo = main.undo_redo
onready var material_layer_popup_menu : PopupMenu = $MaterialLayerPopupMenu
onready var map_type_popup_menu : PopupMenu = $MapTypePopupMenu

func _ready() -> void:
	set_column_expand(0, false)
	set_column_min_width(0, 100)


func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT and event.pressed:
		var layer = get_layer_at_position(event.position)
		if layer:
			material_layer_popup_menu.rect_global_position = event.global_position
			material_layer_popup_menu.layer = layer
			material_layer_popup_menu.layer_texture_selected = layer is MaterialLayer and layer in _selected_layer_textures
			material_layer_popup_menu.popup()
	elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		# `get_selected` returns null the first time a layer is clicked
		# if it doesn't, in thin case it means the layer was "double clicked"
		if get_selected():
			get_selected().set_editable(1, true)
			# if a layer was set editable reset it to not editable again
			if _lastly_edited_layer:
				_lastly_edited_layer.set_editable(1, false)
			_lastly_edited_layer = get_selected()


func get_drag_data(_position : Vector2):
	var selected_layers := []
	var selected = get_next_selected(null)
	var preview := VBoxContainer.new()
	var type = _get_layer_type(selected)
	while selected:
		if _get_layer_type(selected) == type:
			selected_layers.append(selected.get_meta("layer"))
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
	if "asset" in data and (data.asset is String or data.asset is MaterialLayer\
			or data.asset is FolderLayer):
		return true
	if data is Dictionary and "type" in data and data.type == "layers" and get_item_at_position(position):
		for layer in data.layers:
			if layer == get_item_at_position(position).get_meta("layer"):
				return false
		var layer_type : int = data.layer_type
		var is_folder := get_layer_at_position(position) is FolderLayer
		var onto_type : int = _get_layer_type(get_item_at_position(position))
		if get_drop_section_at_position(position) == 0:
			return (layer_type == LayerType.TEXTURE_LAYER and\
					onto_type == LayerType.MATERIAL_LAYER and not is_folder) or\
					(layer_type == onto_type and is_folder)
		else:
			return layer_type == onto_type
	return false


func drop_data(position : Vector2, data) -> void:
	if data is Dictionary and "type" in data and data.type == "layers":
		undo_redo.create_action("Rearrange Layers")
		var onto_layer = get_layer_at_position(position)
		match get_drop_section_at_position(position):
			0:
				var onto_array : Array
				if onto_layer is MaterialLayer:
					onto_array = _selected_layer_textures[onto_layer].layers
				else:
					onto_array = onto_layer.layers
				for layer in data.layers:
					var new_layer = layer.duplicate()
					undo_redo.add_do_method(self, "add_layer_to_array", new_layer, onto_array)
					undo_redo.add_undo_method(self, "remove_layer_from_array", new_layer, onto_array)
			var section:
				var onto_array : Array = main.editing_layer_material.get_parent(onto_layer).layers
				var onto_position := onto_array.find(onto_layer)
				if section == 1:
					onto_position += 1
				onto_position = int(clamp(onto_position, 0, onto_array.size()))
				data.layers.invert()
				for layer in data.layers:
					var new_layer = layer.duplicate()
					undo_redo.add_do_method(self, "insert_layer_to_array", new_layer, onto_array, onto_position)
					undo_redo.add_undo_method(self, "remove_layer_from_array", new_layer, onto_array)
		
		for layer in data.layers:
			var in_array : Array = main.editing_layer_material.get_parent(layer).layers
			var layer_position = in_array.find(layer)
			undo_redo.add_do_method(self, "remove_layer_from_array", layer, in_array)
			undo_redo.add_undo_method(self, "insert_layer_to_array", layer, in_array, layer_position)
		undo_redo.add_do_method(self, "reload")
		undo_redo.add_undo_method(self, "reload")
		undo_redo.commit_action()
	elif "asset" in data:
		if data.asset is String:
			undo_redo.create_action("Add Texture From Library")
			var layer := FileTextureLayer.new()
			layer.name = data.asset.get_file().get_basename()
			layer.path = data.asset
			undo_redo.add_do_method(main, "add_layer", layer, _selected_layer_textures[get_layer_at_position(position)])
			undo_redo.add_undo_method(main, "delete_layer", layer)
			undo_redo.commit_action()
		elif data.asset is MaterialLayer or data.asset is FolderLayer:
			undo_redo.create_action("Add Material From Library")
			undo_redo.add_do_method(main, "add_layer", data.asset, main.editing_layer_material)
			undo_redo.add_undo_method(main, "delete_layer", data.asset)
			undo_redo.commit_action()


func insert_layer_to_array(layer, array : Array, position : int) -> void:
	array.insert(position, layer)


func add_layer_to_array(layer, array : Array) -> void:
	array.append(layer)


func remove_layer_from_array(layer, array : Array) -> void:
	array.erase(layer)


func set_editing_layer_material(to) -> void:
	editing_layer_material = to
	_tree_items = {}
	clear()
	_root = create_item()
	for material_layer in editing_layer_material.layers:
		_setup_material_layer_item(material_layer, _root)
	update_icons()


func reload() -> void:
	set_editing_layer_material(editing_layer_material)


func update_icons() -> void:
	for layer in _tree_items:
		var tree_item : TreeItem = _tree_items[layer]
		if layer is TextureLayer:
			tree_item.set_button(0, 0, yield(layer.generate_result(Vector2(16, 16), false), "completed"))
		elif layer is MaterialLayer:
			var button_count := 0
			if layer.mask:
				tree_item.set_button(0, 0, yield(layer.mask.generate_result(Vector2(32, 32), false), "completed"))
				button_count += 1
			if layer.maps.size() > 0:
				if layer in _selected_maps:
					var selected_map : LayerTexture = _selected_maps[layer]
					tree_item.set_button(0, button_count, yield(selected_map.generate_result(Vector2(32, 32), false), "completed"))
		tree_item.set_button(1, 0, preload("res://icons/icon_visible.svg") if layer.visible else preload("res://icons/icon_hidden.svg"))


func select_map(layer : MaterialLayer, map : String, expand := false) -> void:
	_selected_maps[layer] = layer.maps[map]
	if expand:
		_selected_layer_textures[layer] = layer.maps[map]


func get_layer_at_position(position : Vector2):
	if get_item_at_position(position):
		return get_item_at_position(position).get_meta("layer")


func get_selected_layer_texture(material_layer : MaterialLayer) -> LayerTexture:
	if material_layer in _selected_layer_textures:
		return _selected_layer_textures[material_layer]
	return null


func get_selected_layer():
	return get_selected().get_meta("layer")


func _on_cell_selected() -> void:
	var layer = get_selected().get_meta("layer")
	if layer is MaterialLayer:
		emit_signal("material_layer_selected", layer)
	elif layer is TextureLayer:
		emit_signal("texture_layer_selected", layer)
	else:
		emit_signal("folder_layer_selected")


func _on_button_pressed(item : TreeItem, _column : int, id : int) -> void:
	var layer = item.get_meta("layer")
	match id:
		Buttons.MAP_DROPDOWN:
			map_type_popup_menu.set_meta("layer", layer)
			map_type_popup_menu.rect_global_position = get_global_transform().xform(get_item_area_rect(item).position)
			map_type_popup_menu.popup()
		Buttons.RESULT:
			if layer is MaterialLayer:
				if layer in _selected_layer_textures and _selected_layer_textures[layer] != layer.mask:
					_selected_layer_textures.erase(layer)
				else:
					_selected_layer_textures[layer] = _selected_maps[layer]
				reload()
		Buttons.MASK:
			if layer in _selected_layer_textures and _selected_layer_textures[layer] == layer.mask:
				_selected_layer_textures.erase(layer)
			else:
				_selected_layer_textures[layer] = layer.mask
			reload()
		Buttons.VISIBILITY:
			undo_redo.create_action("Toggle Layer Visibility")
			undo_redo.add_do_property(layer, "visible", not layer.visible)
			undo_redo.add_do_method(self, "emit_signal", "layer_visibility_changed", layer)
			undo_redo.add_undo_property(layer, "visible", layer.visible)
			undo_redo.add_undo_method(self, "emit_signal", "layer_visibility_changed", layer)
			undo_redo.commit_action()
		Buttons.ICON:
			if layer in _expanded_folders:
				_expanded_folders.erase(layer)
			else:
				_expanded_folders.append(layer)
			reload()


func _on_MapTypePopupMenu_about_to_show() -> void:
	map_type_popup_menu.clear()
	var layer : MaterialLayer = map_type_popup_menu.get_meta("layer")
	for map in layer.maps:
		map_type_popup_menu.add_item(map)
		var icon : ImageTexture = yield(
			layer.maps[map].generate_result(Vector2(32, 32), false), "completed")
		map_type_popup_menu.set_item_icon(map_type_popup_menu.get_item_count() - 1, icon)


func _on_MapTypePopupMenu_id_pressed(id : int) -> void:
	var layer : MaterialLayer = map_type_popup_menu.get_meta("layer")
	var selected_map : LayerTexture = layer.maps.values()[id]
	_selected_maps[layer] = selected_map
	_selected_layer_textures[layer] = selected_map
	reload()


func _draw_material_layer_item(material_layer_item : TreeItem, item_rect : Rect2) -> void:
	var material_layer = material_layer_item.get_meta("layer")
	if not material_layer is MaterialLayer:
		return
	if not material_layer in _selected_layer_textures:
		return
	var selected : LayerTexture = _selected_layer_textures[material_layer]
	var mask_pos := 25
	var map_pos := 68
	var icon_rect := Rect2(Vector2(
			mask_pos if selected == material_layer.mask else map_pos,
			3 + item_rect.position.y), Vector2(32, 32))
	if material_layer.maps.size() > 1:
		icon_rect.position.x -= 23
	draw_rect(icon_rect, Color.dodgerblue, false, 2.0)


func _on_item_edited() -> void:
	undo_redo.create_action("Rename Layer")
	var edited_layer = get_edited().get_meta("layer")
	undo_redo.add_do_property(edited_layer, "name", get_edited().get_text(get_edited_column()))
	undo_redo.add_undo_property(edited_layer, "name", edited_layer.name)
	undo_redo.add_undo_method(_tree_items[edited_layer], "set_text", 1, edited_layer.name)
	undo_redo.commit_action()
	_lastly_edited_layer = null


func _get_layer_type(layer_item : TreeItem) -> int:
	return LayerType.TEXTURE_LAYER if layer_item.has_meta("layer_texture") else LayerType.MATERIAL_LAYER


func _setup_material_layer_item(material_layer, parent_item : TreeItem) -> void:
	var material_layer_item := create_item(parent_item)
	material_layer_item.set_meta("layer", material_layer)
	material_layer_item.custom_minimum_height = 32
	
	if material_layer is MaterialLayer:
		if material_layer in _selected_layer_textures:
			var selected_layer_texture : LayerTexture = _selected_layer_textures[material_layer]
			for texture_layer in selected_layer_texture.layers:
				_setup_texture_layer_item(texture_layer, material_layer_item, selected_layer_texture)
		
		if not material_layer in _selected_maps and material_layer.maps.size() > 0:
			_selected_maps[material_layer] = material_layer.maps.values().front()
		
		if material_layer.mask:
			material_layer_item.add_button(0, _empty_texture, Buttons.MASK)
		if material_layer.maps.size() > 0:
			material_layer_item.add_button(0, _empty_texture, Buttons.RESULT)
		if material_layer.maps.size() > 1:
			material_layer_item.add_button(0, preload("res://icons/down.svg"), Buttons.MAP_DROPDOWN)
	else:
		var icon : Texture = preload("res://icons/open_folder.svg") if material_layer in _expanded_folders else preload("res://icons/large_folder.svg")
		material_layer_item.add_button(0, icon, Buttons.ICON)
	
	material_layer_item.set_text(1, material_layer.name)
	material_layer_item.add_button(1, _empty_texture, Buttons.VISIBILITY)
	
	material_layer_item.set_custom_draw(0, self, "_draw_material_layer_item")
	material_layer_item.set_cell_mode(0, TreeItem.CELL_MODE_CUSTOM)
	
	_tree_items[material_layer] = material_layer_item
	
	if material_layer is FolderLayer and material_layer in _expanded_folders:
		for layer in material_layer.layers:
			_setup_material_layer_item(layer, material_layer_item)


func _setup_texture_layer_item(texture_layer, parent_item : TreeItem, layer_texture : LayerTexture) -> void:
	var texture_layer_item := create_item(parent_item)
	texture_layer_item.set_meta("layer", texture_layer)
	texture_layer_item.set_meta("layer_texture", layer_texture)
	texture_layer_item.custom_minimum_height = 16
	
	if texture_layer is TextureLayer:
		texture_layer_item.add_button(0, _small_empty_texture, Buttons.RESULT)
	else:
		var icon : Texture = preload("res://icons/open_folder.svg") if texture_layer in _expanded_folders else preload("res://icons/large_folder.svg")
		texture_layer_item.add_button(0, icon, Buttons.ICON)
	texture_layer_item.set_text(1, texture_layer.name)
	texture_layer_item.add_button(1, _empty_texture, Buttons.VISIBILITY)
	_tree_items[texture_layer] = texture_layer_item
	if texture_layer is FolderLayer and texture_layer in _expanded_folders:
		for layer in texture_layer.layers:
			_setup_texture_layer_item(layer, texture_layer_item, layer_texture)


func _on_MaterialLayerPopupMenu_mask_added() -> void:
	get_selected_layer().mask = LayerTexture.new()
	reload()
