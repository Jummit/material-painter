extends Tree

"""
An interactive representation of a `LayerMaterial` as a tree

The tree consists of a list of `MaterialLayer`s with the `TextureLayer`s
of the selected `LayerTexture` below. The selected `TextureLayer`,
which could be a map or a mask, is stored in `_selected_layer_textures`.
Shows previews of maps and masks as buttons, which can be clicked to select the
`LayerTexture`. 
When a `MaterialLayer` has multiple maps enabled, the current map can be selected
with a dropdown. The selected maps are stored in `_selected_maps`.
"""

var _root : TreeItem
var _lastly_edited_layer : TreeItem
var _selected_layer_textures : Dictionary
var _selected_maps : Dictionary
var _expanded_folders : Array

var undo_redo := Globals.undo_redo

signal material_layer_selected(material_layer)
signal texture_layer_selected(texture_layer)
# warning-ignore:unused_signal
signal layer_deselected
signal folder_layer_selected

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

const LayerMaterial = preload("res://resources/material/layer_material.gd")
const MaterialLayer = preload("res://resources/material/material_layer.gd")
const LayerTexture = preload("res://resources/texture/layer_texture.gd")
const TextureLayer = preload("res://resources/texture/texture_layer.gd")
const FileTextureLayer = preload("res://resources/texture/layers/file_texture_layer.gd")
const TextureFolder = preload("res://resources/texture/texture_folder.gd")
const MaterialFolder = preload("res://resources/material/material_folder.gd")
const Asset = preload("res://main/asset_browser.gd").Asset
const TextureAssetType = preload("res://main/asset_browser.gd").TextureAssetType
const MaterialAssetType = preload("res://main/asset_browser.gd").MaterialAssetType
const EffectAssetType = preload("res://main/asset_browser.gd").EffectAssetType

onready var layer_popup_menu : PopupMenu = $LayerPopupMenu
onready var map_type_popup_menu : PopupMenu = $MapTypePopupMenu

func _ready() -> void:
	set_column_expand(0, false)
	set_column_min_width(0, 100)
	Globals.connect("current_file_changed", self,
			"_on_Globals_current_file_changed")
	Globals.connect("editing_layer_material_changed", self,
			"_on_Globals_editing_layer_material_changed")


func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT\
			and event.pressed:
		var layer = _get_layer_at_position(event.position)
		layer_popup_menu.rect_global_position = event.global_position
		layer_popup_menu.layer = layer
		if layer is MaterialLayer and layer in _selected_layer_textures:
			layer_popup_menu.layer_texture = _selected_layer_textures[layer]
		elif layer is TextureFolder:
			layer_popup_menu.layer_texture = layer.get_layer_texture_in()
		layer_popup_menu.popup()
	elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT\
			and event.pressed:
		# `get_selected` returns null the first time a layer is clicked
		# if it doesn't, in thin case it means the layer was "double clicked"
		if get_selected():
			get_selected().set_editable(1, true)
			# if a layer was set editable reset it to not editable again
			if is_instance_valid(_lastly_edited_layer):
				_lastly_edited_layer.set_editable(1, false)
			_lastly_edited_layer = get_selected()
	elif event is InputEventKey and event.pressed and event.scancode == KEY_DELETE:
		var layer = get_selected_layer()
		undo_redo.create_action("Delete Layer")
		undo_redo.add_do_method(Globals.editing_layer_material, "delete_layer",
				layer)
		undo_redo.add_do_method(self, "emit_signal", "layer_deselected")
		undo_redo.add_undo_method(Globals.editing_layer_material, "add_layer",
				layer, layer.parent)
		undo_redo.add_undo_method(self, "_emit_select_signal", layer)
		undo_redo.commit_action()


func get_selected_layer_texture(material_layer : MaterialLayer) -> LayerTexture:
	if material_layer in _selected_layer_textures:
		return _selected_layer_textures[material_layer]
	return null


func get_selected_layer():
	if not get_selected():
		return null
	return get_selected().get_meta("layer")


func is_folder(layer) -> bool:
	return layer is TextureFolder or layer is MaterialFolder


func _on_cell_selected() -> void:
	_emit_select_signal(get_selected().get_meta("layer"))


func _on_button_pressed(item : TreeItem, _column : int, id : int) -> void:
	var layer = item.get_meta("layer")
	match id:
		Buttons.MAP_DROPDOWN:
			map_type_popup_menu.set_meta("layer", layer)
			map_type_popup_menu.rect_global_position =\
					get_global_transform().xform(get_item_area_rect(item).position)
			map_type_popup_menu.popup()
		Buttons.RESULT:
			if layer is MaterialLayer:
				if layer in _selected_layer_textures and\
						_selected_layer_textures[layer] != layer.mask:
					_selected_layer_textures.erase(layer)
				else:
					_selected_layer_textures[layer] = _selected_maps[layer]
				_load_layer_material()
		Buttons.MASK:
			if layer in _selected_layer_textures and\
					_selected_layer_textures[layer] == layer.mask:
				_selected_layer_textures.erase(layer)
			else:
				_selected_layer_textures[layer] = layer.mask
			_load_layer_material()
		Buttons.VISIBILITY:
			var parent
			if layer is MaterialLayer or layer is MaterialFolder:
				parent = layer.get_layer_material_in()
			elif layer is TextureLayer or layer is TextureFolder:
				parent = layer.get_layer_texture_in()
			undo_redo.create_action("Toggle Layer Visibility")
			undo_redo.add_do_property(layer, "visible", not layer.visible)
			undo_redo.add_do_method(parent, "mark_dirty", true)
			undo_redo.add_do_method(Globals.editing_layer_material, "update")
			undo_redo.add_undo_property(layer, "visible", layer.visible)
			undo_redo.add_undo_method(parent, "mark_dirty", true)
			undo_redo.add_undo_method(Globals.editing_layer_material, "update")
			undo_redo.commit_action()
		Buttons.ICON:
			if layer in _expanded_folders:
				_expanded_folders.erase(layer)
			else:
				_expanded_folders.append(layer)
			_load_layer_material()


func _on_MapTypePopupMenu_about_to_show() -> void:
	map_type_popup_menu.clear()
	var layer : MaterialLayer = map_type_popup_menu.get_meta("layer")
	for map in layer.maps:
		map_type_popup_menu.add_item(map)
		map_type_popup_menu.set_item_icon(
				map_type_popup_menu.get_item_count() - 1, layer.maps[map].icon)


func _on_MapTypePopupMenu_id_pressed(id : int) -> void:
	var layer : MaterialLayer = map_type_popup_menu.get_meta("layer")
	var selected_map : LayerTexture = layer.maps.values()[id]
	_selected_maps[layer] = selected_map
	_selected_layer_textures[layer] = selected_map
	_load_layer_material()


func _on_item_edited() -> void:
	undo_redo.create_action("Rename Layer")
	var edited_layer = get_edited().get_meta("layer")
	undo_redo.add_do_property(edited_layer, "name", get_edited().get_text(1))
	undo_redo.add_do_method(self, "_load_layer_material")
	undo_redo.add_undo_method(self, "_load_layer_material")
	undo_redo.add_undo_property(edited_layer, "name", edited_layer.name)
	undo_redo.add_undo_method(self, "_load_layer_material")
	undo_redo.commit_action()
	_lastly_edited_layer = null


func _on_TextureMapButtons_changed(map : String, enabled : bool) -> void:
	if enabled and get_selected_layer():
		_select_map(get_selected_layer(), map, true)


func _on_Globals_editing_layer_material_changed() -> void:
	Globals.editing_layer_material.connect("results_changed", self,
			"_on_LayerMaterial_results_changed")
	_load_layer_material()


func _on_Globals_current_file_changed() -> void:
	_load_layer_material()


func _on_LayerMaterial_results_changed() -> void:
	_load_layer_material()


func _draw_material_layer_item(material_layer_item : TreeItem, item_rect : Rect2) -> void:
	var material_layer = material_layer_item.get_meta("layer")
	if not material_layer is MaterialLayer or\
			not material_layer in _selected_layer_textures:
		return
	var icon_rect := Rect2(Vector2(68, item_rect.position.y - 1), Vector2(32, 32))
	if _selected_layer_textures[material_layer] == material_layer.mask and\
			material_layer.maps.size() > 0:
		icon_rect.position.x = 23
	if material_layer.maps.size() > 1:
		icon_rect.position.x -= 31
	draw_rect(icon_rect, Color.dodgerblue, false, 2.0)


func get_drag_data(_position : Vector2):
	var selected_layers := []
	var selected = get_next_selected(null)
	if not selected:
		return
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
	if data is Asset and data.type is TextureAssetType and\
			_get_layer_at_position(position) is MaterialLayer and\
			get_selected_layer_texture(_get_layer_at_position(position)):
		return true
	if data is Asset and data.type is MaterialAssetType:
		return true
	var layer_data := _get_layers_of_drop_data(data)
	if not layer_data.empty():
		var layers : Array = layer_data.layers
		var layer_type : int = layer_data.type
		if get_item_at_position(position):
			for layer in layers:
				if layer == get_item_at_position(position).get_meta("layer"):
					return false
			var is_folder := is_folder(_get_layer_at_position(position))
			var onto_type : int = _get_layer_type(get_item_at_position(position))
			if get_drop_section_at_position(position) == 0:
				return (layer_type == LayerType.TEXTURE_LAYER and\
						onto_type == LayerType.MATERIAL_LAYER and not is_folder) or\
						(layer_type == onto_type and is_folder)
			else:
				return layer_type == onto_type or layer_type == LayerType.MATERIAL_LAYER
		else:
			return layer_type == LayerType.MATERIAL_LAYER
	return false


func drop_data(position : Vector2, data) -> void:
	var layer_data := _get_layers_of_drop_data(data)
	if not layer_data.empty():
		var layers : Array = layer_data.layers
		undo_redo.create_action("Rearrange Layers")
		var onto_layer = _get_layer_at_position(position)
		var onto
		var onto_position : int
		match get_drop_section_at_position(position):
			0:
				if onto_layer is MaterialLayer:
					onto = _selected_layer_textures[onto_layer]
				else:
					onto = onto_layer
				onto_position = onto.layers.size()
			-100:
				onto = Globals.editing_layer_material
				onto_position = onto.layers.size()
			var section:
				onto = onto_layer.parent
				onto_position = onto.layers.find(onto_layer)
				if section == 1:
					onto_position += 1
				onto_position = int(clamp(onto_position, 0, onto.layers.size()))
				layers.invert()
		
		for layer in layers:
			if layer.parent:
				var layer_position = layer.parent.layers.find(layer)
				var new_layer = layer.duplicate()
				
				undo_redo.add_do_method(Globals.editing_layer_material,
						"add_layer", new_layer, onto, onto_position)
				undo_redo.add_do_method(Globals.editing_layer_material,
						"delete_layer", layer)
				undo_redo.add_undo_method(Globals.editing_layer_material,
						"delete_layer", new_layer)
				undo_redo.add_undo_method(Globals.editing_layer_material,
						"add_layer", layer, layer.parent, layer_position)
			else:
				undo_redo.add_do_method(Globals.editing_layer_material,
						"add_layer", layer, onto)
				undo_redo.add_undo_method(Globals.editing_layer_material,
						"delete_layer", layer)
			
		
		undo_redo.add_do_method(self, "_load_layer_material")
		undo_redo.add_undo_method(self, "_load_layer_material")
		undo_redo.commit_action()
	elif data is Asset:
		if data.type is TextureAssetType:
			undo_redo.create_action("Add Texture From Library")
			var layer := FileTextureLayer.new()
			layer.name = data.name
			if not data.data.begins_with("user://"):
				layer.path = "local" + data.data.substr(
						Globals.current_file.resource_path.get_base_dir().length())
			else:
				layer.path = data.data
			undo_redo.add_do_method(Globals.editing_layer_material, "add_layer",
					layer, _selected_layer_textures[_get_layer_at_position(position)])
			undo_redo.add_undo_method(Globals.editing_layer_material,
					"delete_layer", layer)
			undo_redo.commit_action()
		elif data.type is MaterialAssetType:
			var new_layer : Resource = data.data.duplicate()
			undo_redo.create_action("Add Material From Library")
			undo_redo.add_do_method(Globals.editing_layer_material, "add_layer",
					new_layer, Globals.editing_layer_material)
			undo_redo.add_undo_method(Globals.editing_layer_material,
					"delete_layer", new_layer)
			undo_redo.commit_action()


func _get_layer_at_position(position : Vector2):
	if get_item_at_position(position):
		return get_item_at_position(position).get_meta("layer")


func _emit_select_signal(layer) -> void:
	if layer is MaterialLayer:
		emit_signal("material_layer_selected", layer)
	elif layer is TextureLayer:
		emit_signal("texture_layer_selected", layer)
	else:
		emit_signal("folder_layer_selected")


func _get_layers_of_drop_data(data) -> Dictionary:
	var layers : Array
	var layer_type : int
	if data is Asset and data.type is EffectAssetType:
		layers = [data.data.duplicate()]
		layer_type = LayerType.TEXTURE_LAYER
	elif data is Dictionary and "type" in data and data.type == "layers":
		layers = data.layers
		layer_type = data.layer_type
	else:
		return {}
	return {
		layers = layers,
		type = layer_type
	}


func _load_layer_material() -> void:
	var selected_layer = get_selected_layer()
	clear()
	_root = create_item()
	for material_layer in Globals.editing_layer_material.layers:
		_setup_material_layer_item(material_layer, _root, selected_layer)


func _select_map(layer : MaterialLayer, map : String, expand := false) -> void:
	_selected_maps[layer] = layer.maps[map]
	if expand:
		_selected_layer_textures[layer] = layer.maps[map]


func _setup_material_layer_item(material_layer, parent_item : TreeItem,
		selected_layer) -> void:
	var material_layer_item := create_item(parent_item)
	if material_layer_item == selected_layer:
		_select_item(material_layer_item)
	material_layer_item.set_meta("layer", material_layer)
	material_layer_item.custom_minimum_height = 32
	
	if material_layer is MaterialLayer:
		if material_layer in _selected_layer_textures:
			if _selected_layer_textures[material_layer].parent != material_layer:
				_selected_layer_textures.erase(material_layer)
			else:
				var selected_layer_texture : LayerTexture =\
						_selected_layer_textures[material_layer]
				for texture_layer in selected_layer_texture.layers:
					_setup_texture_layer_item(texture_layer, material_layer_item,
							selected_layer_texture, selected_layer)
		
		if not material_layer in _selected_maps and material_layer.maps.size() > 0:
			_selected_maps[material_layer] = material_layer.maps.values().front()
		
		if material_layer.mask:
			material_layer_item.add_button(0, material_layer.mask.icon,
					Buttons.MASK)
		if material_layer.maps.size() > 0:
			material_layer_item.add_button(0, _selected_maps[material_layer].icon,
					Buttons.RESULT)
		if material_layer.maps.size() > 1:
			material_layer_item.add_button(0, preload("res://icons/down.svg"),
					Buttons.MAP_DROPDOWN)
	elif material_layer is MaterialFolder:
		var icon : Texture = preload("res://icons/open_folder.svg") if\
				material_layer in _expanded_folders else\
				preload("res://icons/large_folder.svg")
		material_layer_item.add_button(0, icon, Buttons.ICON)
		material_layer_item.set_tooltip(1,
				"%s (contains %s layers)" % [material_layer.name,
				material_layer.layers.size()])
	
	material_layer_item.set_text(1, material_layer.name)
	material_layer_item.add_button(1, _get_visibility_icon(material_layer.visible),
			Buttons.VISIBILITY)
	
	material_layer_item.set_custom_draw(0, self, "_draw_material_layer_item")
	material_layer_item.set_cell_mode(0, TreeItem.CELL_MODE_CUSTOM)
	
	if material_layer is MaterialFolder and material_layer in _expanded_folders:
		for layer in material_layer.layers:
			_setup_material_layer_item(layer, material_layer_item, selected_layer)


func _setup_texture_layer_item(texture_layer, parent_item : TreeItem,
		layer_texture : LayerTexture, selected_layer) -> void:
	var texture_layer_item := create_item(parent_item)
	if texture_layer == selected_layer:
		_select_item(texture_layer_item)
	texture_layer_item.set_meta("layer", texture_layer)
	texture_layer_item.custom_minimum_height = 16
	
	if texture_layer is TextureLayer:
		texture_layer_item.add_button(0, texture_layer.icon, Buttons.RESULT)
		texture_layer_item.set_tooltip(1,
				"%s (%s Layer)" % [texture_layer.name, texture_layer.type_name])
	else:
		var icon : Texture = preload("res://icons/open_folder.svg") if\
				texture_layer in _expanded_folders else\
				preload("res://icons/large_folder.svg")
		texture_layer_item.add_button(0, icon, Buttons.ICON)
	texture_layer_item.set_text(1, texture_layer.name)
	texture_layer_item.add_button(1, _get_visibility_icon(texture_layer.visible),
			Buttons.VISIBILITY)
	if texture_layer is TextureFolder and texture_layer in _expanded_folders:
		for layer in texture_layer.layers:
			_setup_texture_layer_item(layer, texture_layer_item, layer_texture,
					selected_layer)


func _get_layer_type(layer_item : TreeItem) -> int:
	if layer_item.get_meta("layer").has_method("get_layer_texture_in"):
		return LayerType.TEXTURE_LAYER
	else:
		return LayerType.MATERIAL_LAYER


func _get_visibility_icon(is_visible : bool) -> Texture:
	return preload("res://icons/icon_visible.svg") if is_visible else\
			preload("res://icons/icon_hidden.svg")


func _select_item(item : TreeItem) -> void:
	# hack to select a `TreeItem` in SelectMode.SELECT_MULTI
	select_mode = Tree.SELECT_SINGLE
	set_block_signals(true)
	item.select(1)
	select_mode = Tree.SELECT_MULTI
	set_block_signals(false)
