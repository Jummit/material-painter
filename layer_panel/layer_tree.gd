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

var layer_material : LayerMaterial setget set_layer_material
var project : ProjectFile
var update_icons := true

var _root : TreeItem
var _lastly_edited_layer : TreeItem
var _selected_maps : Dictionary
var _layer_states : Dictionary
var _painting := false

onready var undo_redo : UndoRedo = find_parent("Main").undo_redo

signal layer_selected(layer)

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

enum LayerState {
	FOLDER_EXPANDED,
	MASK_EXPANDED,
	MAP_EXPANDED
}

const LayerMaterial = preload("res://resources/material/layer_material.gd")
const MaterialLayer = preload("res://resources/material/material_layer.gd")
const LayerTexture = preload("res://resources/texture/layer_texture.gd")
const TextureLayer = preload("res://resources/texture/texture_layer.gd")
const FileTextureLayer = preload("res://resources/texture/layers/file_texture_layer.gd")
const BitmapTextureLayer = preload("res://resources/texture/layers/bitmap_texture_layer.gd")
const TextureFolder = preload("res://resources/texture/texture_folder.gd")
const MaterialFolder = preload("res://resources/material/material_folder.gd")
const Asset = preload("res://asset_browser/asset_classes.gd").Asset
const TextureAssetType = preload("res://asset_browser/asset_classes.gd").TextureAssetType
const MaterialAssetType = preload("res://asset_browser/asset_classes.gd").MaterialAssetType
const EffectAssetType = preload("res://asset_browser/asset_classes.gd").EffectAssetType
const ProjectFile = preload("res://resources/project_file.gd")

onready var layer_popup_menu : PopupMenu = $LayerPopupMenu
onready var map_type_popup_menu : PopupMenu = $MapTypePopupMenu

func _ready() -> void:
	set_column_expand(0, false)
	set_column_min_width(0, 100)


func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT\
		and event.pressed:
		var layer = _get_layer_at_position(event.position)
		layer_popup_menu.rect_global_position = event.global_position
		layer_popup_menu.layer = layer
		if get_selected_layer_texture(layer):
			layer_popup_menu.layer_texture = get_selected_layer_texture(layer)
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
	elif event is InputEventKey and event.pressed and\
			event.scancode == KEY_DELETE:
		var layer = get_selected_layer()
		undo_redo.create_action("Delete Layer")
		undo_redo.add_do_method(layer_material, "delete_layer",
			layer)
		undo_redo.add_do_method(self, "reload")
		undo_redo.add_undo_method(layer_material, "add_layer",
			layer, layer.parent)
		undo_redo.add_undo_method(self, "_emit_select_signal", layer)
		undo_redo.add_undo_method(self, "reload")
		undo_redo.commit_action()


func get_selected_layer_texture(layer) -> LayerTexture:
	if not layer in _layer_states:
		return null
	match _layer_states[layer]:
		LayerState.MAP_EXPANDED:
			return _selected_maps[layer]
		LayerState.MASK_EXPANDED:
			return layer.mask
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
				if layer in _layer_states and\
						_layer_states[layer] == LayerState.MAP_EXPANDED:
					_layer_states.erase(layer)
				else:
					_layer_states[layer] = LayerState.MAP_EXPANDED
				reload()
		Buttons.MASK:
			if layer in _layer_states and\
					_layer_states[layer] == LayerState.MASK_EXPANDED:
				_layer_states.erase(layer)
			else:
				_layer_states[layer] = LayerState.MASK_EXPANDED
			reload()
		Buttons.VISIBILITY:
			undo_redo.create_action("Toggle Layer Visibility")
			undo_redo.add_do_property(layer, "visible", not layer.visible)
			undo_redo.add_do_method(layer.parent, "mark_dirty", true)
			undo_redo.add_do_method(layer_material, "update")
			undo_redo.add_do_method(self, "reload")
			undo_redo.add_undo_property(layer, "visible", layer.visible)
			undo_redo.add_undo_method(layer.parent, "mark_dirty", true)
			undo_redo.add_undo_method(layer_material, "update")
			undo_redo.add_undo_method(self, "reload")
			undo_redo.commit_action()
		Buttons.ICON:
			if layer in _layer_states and\
					_layer_states[layer] == LayerState.FOLDER_EXPANDED:
				_layer_states.erase(layer)
			else:
				_layer_states[layer] = LayerState.FOLDER_EXPANDED
			reload()


func _on_MapTypePopupMenu_about_to_show() -> void:
	map_type_popup_menu.clear()
	var layer : MaterialLayer = map_type_popup_menu.get_meta("layer")
	for map in layer.maps:
		map_type_popup_menu.add_item(map)
		var icon = _get_icon(layer.maps[map])
		if icon is GDScriptFunctionState:
			icon = yield(icon, "completed")
		map_type_popup_menu.set_item_icon(
				map_type_popup_menu.get_item_count() - 1, icon)


func _on_MapTypePopupMenu_id_pressed(id : int) -> void:
	var layer : MaterialLayer = map_type_popup_menu.get_meta("layer")
	_selected_maps[layer] = layer.maps.values()[id]
	reload()


func _on_item_edited() -> void:
	undo_redo.create_action("Rename Layer")
	var edited_layer = get_edited().get_meta("layer")
	undo_redo.add_do_property(edited_layer, "name", get_edited().get_text(1))
	undo_redo.add_do_method(self, "reload")
	undo_redo.add_undo_method(self, "reload")
	undo_redo.add_undo_property(edited_layer, "name", edited_layer.name)
	undo_redo.add_undo_method(self, "reload")
	undo_redo.commit_action()
	_lastly_edited_layer = null


func _on_TextureMapButtons_changed(map : String, enabled : bool) -> void:
	if enabled and get_selected_layer():
		_select_map(get_selected_layer(), map, true)


func _draw_layer_item(item : TreeItem, item_rect : Rect2) -> void:
	var layer = item.get_meta("layer")
	if not layer in _layer_states:
		return
	var state : int = _layer_states[layer]
	if not state in [LayerState.MAP_EXPANDED, LayerState.MASK_EXPANDED]:
		return
	var icon_rect := Rect2(Vector2(64, item_rect.position.y), Vector2(32, 32))
	if layer.mask and (layer is MaterialFolder or layer.maps.size()) and\
			state == LayerState.MASK_EXPANDED:
		icon_rect.position.x -= 46
	if layer is MaterialLayer and layer.maps.size() > 1:
		icon_rect.position.x -= 28
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
	var layer_data := _get_layers_of_drop_data(data, position)
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
				return layer_type == onto_type or\
						layer_type == LayerType.MATERIAL_LAYER
		else:
			return layer_type == LayerType.MATERIAL_LAYER
	return false


func drop_data(position : Vector2, data) -> void:
	var layer_data := _get_layers_of_drop_data(data, position)
	if layer_data.empty():
		return
	var layers : Array = layer_data.layers
	var onto_layer = _get_layer_at_position(position)
	var onto
	var onto_position : int
	match get_drop_section_at_position(position):
		0:
			# dropped onto layer
			if layer_data.type == LayerType.TEXTURE_LAYER:
				if onto_layer is TextureFolder:
					onto = onto_layer
				else:
					# it's a material layer or folder
					onto = get_selected_layer_texture(onto_layer)
			else:
				# it's a material folder
				onto = onto_layer
			onto_position = onto.layers.size()
		-100:
			# dropped onto nothing
			onto = layer_material
			onto_position = onto.layers.size()
		var section:
			# dropped above/below layer
			# FIXME: this produces wrong results when droping a layer down
			onto = onto_layer.parent
			onto_position = onto.layers.find(onto_layer)
			if section == 1:
				onto_position += 1
			onto_position = int(clamp(onto_position, 0, onto.layers.size() - 1))
	
	# add the layers in the reverse order to keep the order intact
	layers.invert()
	
	var layer_mat := layer_material
	if layers[0].parent:
		undo_redo.create_action("Rearrange Layers")
	else:
		undo_redo.create_action("Drop Layers")
	for layer in layers:
		var new_layer = layer
		if layer.parent:
			var old_layer_position : int = layer.parent.layers.find(layer)
			# delete the old layer
			undo_redo.add_do_method(layer_mat, "delete_layer", layer, false)
			# add the new layer
			undo_redo.add_do_method(layer_mat, "add_layer", new_layer, onto,
					onto_position, false)
			# delete the new layer
			undo_redo.add_undo_method(layer_mat, "delete_layer", new_layer,
					false)
			# restore the old layer
			undo_redo.add_undo_method(layer_mat, "add_layer", layer,
					layer.parent, old_layer_position, false)
		else:
			undo_redo.add_do_method(layer_mat, "add_layer", new_layer, onto,
					onto_position, false)
			undo_redo.add_undo_method(layer_mat, "delete_layer", new_layer,
					false)
	
	undo_redo.add_do_method(layer_mat, "update")
	undo_redo.add_undo_method(layer_mat, "update")
	undo_redo.add_do_method(self, "reload")
	undo_redo.add_undo_method(self, "reload")
	undo_redo.commit_action()


func reload() -> void:
	set_layer_material(layer_material)


func _get_layer_at_position(position : Vector2):
	if get_item_at_position(position):
		return get_item_at_position(position).get_meta("layer")


func _emit_select_signal(layer) -> void:
	_painting = layer is BitmapTextureLayer
	emit_signal("layer_selected", layer)


func _get_layers_of_drop_data(data, position : Vector2) -> Dictionary:
	var layers : Array
	var layer_type : int
	if data is Asset and data.type is EffectAssetType:
		layers = [data.data.duplicate()]
		layer_type = LayerType.TEXTURE_LAYER
	elif data is Asset and data.type is TextureAssetType:
		var layer := FileTextureLayer.new()
		layer.path = data.file.replace(project.resource_path.get_base_dir(), "local:/")
		layer.name = data.file.get_file().get_basename()
		
		if get_selected_layer_texture(_get_layer_at_position(position)) or\
				_get_layer_at_position(position) is TextureFolder or\
				_get_layer_at_position(position) is TextureLayer:
			layers = [layer]
			layer_type = LayerType.TEXTURE_LAYER
		else:
			# create a material layer with the dropped texture as normal or albedo
			var layer_texture := LayerTexture.new()
			layer_texture.layers.append(layer)
			
			var material_layer := MaterialLayer.new()
			var map := "normal" if "normal" in data.tags else "albedo"
			material_layer.maps[map] = layer_texture
			material_layer.name = data.name.replace("normal", "").replace("albedo", "").capitalize()
			
			layer_texture.parent = material_layer
			layer.parent = layer_texture
			
			layers = [material_layer]
			layer_type = LayerType.MATERIAL_LAYER
	elif data is Asset and data.type is MaterialAssetType:
		var material_layer : Resource = data.data.duplicate()
		var mat_layers := []
		if material_layer is MaterialFolder:
			mat_layers = material_layer.layers
		else:
			mat_layers = [material_layer]
		while mat_layers.size():
			var mat_layer : Resource = mat_layers.pop_back()
			if mat_layer is MaterialFolder:
				mat_layers += mat_layer.layers
		layer_type = LayerType.MATERIAL_LAYER
		layers = [material_layer]
	elif data is Dictionary and "type" in data and data.type == "layers":
		layers = data.layers
		layer_type = data.layer_type
	else:
		return {}
	return {
		layers = layers,
		type = layer_type
	}


func set_layer_material(to : LayerMaterial) -> void:
	layer_material = to
	var selected_layer = get_selected_layer()
	clear()
	_root = create_item()
	for material_layer in layer_material.layers:
		_setup_material_layer_item(material_layer, _root, selected_layer)


func _select_map(layer : MaterialLayer, map : String, expand := false) -> void:
	_selected_maps[layer] = layer.maps[map]
	if expand:
		_layer_states[layer] = LayerState.MAP_EXPANDED
	reload()


func _setup_material_layer_item(layer, parent_item : TreeItem,
	selected_layer) -> void:
	var item := create_item(parent_item)
	if layer == selected_layer:
		_select_item(item)
	item.custom_minimum_height = 32
	item.set_meta("layer", layer)
	item.set_text(1, layer.name)
	item.add_button(1, _get_visibility_icon(layer.visible),
		Buttons.VISIBILITY)
	
	item.set_custom_draw(0, self, "_draw_layer_item")
	item.set_cell_mode(0, TreeItem.CELL_MODE_CUSTOM)
	
	var state := -1 if not layer in _layer_states else _layer_states[layer]
	
	if layer.mask:
		var icon = _get_icon(layer.mask)
		if icon is GDScriptFunctionState:
			icon = yield(icon, "completed")
		if not is_instance_valid(item):
			return
		if icon is Texture:
			item.add_button(0, icon, Buttons.MASK)
	
	if get_selected_layer_texture(layer):
		for texture_layer in get_selected_layer_texture(layer).layers:
			_setup_texture_layer_item(texture_layer, item, selected_layer)
	if layer is MaterialLayer:
		if layer in _selected_maps and _selected_maps[layer] and not (
				_selected_maps[layer] in layer.maps.values()):
			_layer_states.erase(layer)
			_selected_maps[layer] = null
		if not layer in _selected_maps and layer.maps.size() > 0:
			_selected_maps[layer] = layer.maps.values().front()
		
		if layer.maps.size() > 0 and _selected_maps[layer]:
			var icon = _get_icon(_selected_maps[layer])
			if icon is GDScriptFunctionState:
				icon = yield(icon, "completed")
			if not is_instance_valid(item):
				return
			if icon is Texture:
				item.add_button(0, icon, Buttons.RESULT)
		
		if layer.maps.size() > 1:
			item.add_button(0, preload("res://icons/down_arrow.svg"),
					Buttons.MAP_DROPDOWN)
	elif layer is MaterialFolder:
		var icon := preload("res://icons/large_folder.svg")
		if state == LayerState.FOLDER_EXPANDED:
			icon = preload("res://icons/large_open_folder.svg")
			for sub_layer in layer.layers:
				_setup_material_layer_item(sub_layer, item, selected_layer)
		item.add_button(0, icon, Buttons.ICON)
		item.set_tooltip(1, "%s (contains %s layers)" % [layer.name,
				layer.layers.size()])


func _setup_texture_layer_item(layer, parent_item : TreeItem,
		selected_layer) -> void:
	var item := create_item(parent_item)
	if layer == selected_layer:
		_select_item(item)
	item.set_meta("layer", layer)
	item.custom_minimum_height = 16
	
	item.set_text(1, layer.name)
	item.add_button(1, _get_visibility_icon(layer.visible), Buttons.VISIBILITY)
	
	if layer is TextureLayer:
		var icon = _get_icon(layer)
		if icon is GDScriptFunctionState:
			icon = yield(icon, "completed")
		if not is_instance_valid(item):
			return
		if icon is Texture:
			item.add_button(0, icon, Buttons.RESULT)
		item.set_tooltip(1,
			"%s (%s Layer)" % [layer.name, layer.type_name])
	else:
		var expanded : bool = layer in _layer_states and\
				_layer_states[layer] == LayerState.FOLDER_EXPANDED
		var icon := preload("res://icons/folder.svg")
		if expanded:
			icon = preload("res://icons/open_folder.svg")
			for sub_layer in layer.layers:
				_setup_texture_layer_item(sub_layer, item, selected_layer)
		item.add_button(0, icon, Buttons.ICON)


func _get_layer_type(item : TreeItem) -> int:
	if item.get_meta("layer") is TextureFolder or item.get_meta("layer") is TextureLayer:
		return LayerType.TEXTURE_LAYER
	else:
		return LayerType.MATERIAL_LAYER


func _get_visibility_icon(is_visible : bool) -> Texture:
	return preload("res://icons/visible.svg") if is_visible else\
		preload("res://icons/hidden.svg")


func _select_item(item : TreeItem) -> void:
	# hack to select a `TreeItem` in SelectMode.SELECT_MULTI
	select_mode = Tree.SELECT_SINGLE
	set_block_signals(true)
	item.select(1)
	select_mode = Tree.SELECT_MULTI
	set_block_signals(false)


func _get_icon(layer):
	if update_icons and not _painting:
		var result = layer.update_icon()
		if result is GDScriptFunctionState:
			yield(result, "completed")
	return layer.icon


func _on_ViewMenuButton_update_icons_toggled() -> void:
	update_icons = not update_icons


func _on_Main_current_file_changed(to : ProjectFile) -> void:
	project = to


func _on_Main_current_layer_material_changed(to : LayerMaterial, _id : int) -> void:
	set_layer_material(to)
