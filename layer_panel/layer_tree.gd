extends Tree

"""
An interactive representation of a `MaterialLayerStack` as a tree
"""

signal layer_selected(layer)

var layer_material : MaterialLayerStack setget set_layer_material
var project : ProjectFile
var update_icons := true
var context : MaterialGenerationContext

# Used to decide which icons to display.
var _selected_map := "albedo"
var _root : TreeItem
var _last_edited_layer : TreeItem
# A map of layers to `LayerState`s.
var _layer_states : Dictionary
# If true, the user is painting and icons are not updated.
var _is_painting := false

# warning-ignore:unsafe_property_access
onready var undo_redo : UndoRedo = find_parent("Main").undo_redo

enum Buttons {
	MASK,
	RESULT,
	ICON,
	VISIBILITY,
}

enum LayerState {
	CLOSED,
	MAP_EXPANDED,
	MASK_EXPANDED,
	FOLDER_EXPANDED,
}

enum Column {
	ICONS,
	NAME,
	OPACITY,
}

const MaterialLayerStack = preload("res://material/material_layer_stack.gd")
const MaterialLayer = preload("res://material/material_layer.gd")
const TextureLayer = preload("res://material/texture_layer.gd")
const TextureAsset = preload("res://asset/assets/texture_asset.gd")
const SmartMaterialAsset = preload("res://asset/assets/smart_material_asset.gd")
const EffectAsset = preload("res://asset/assets/effect_asset.gd")
const ProjectFile = preload("res://main/project_file.gd")
const LayerPopupMenu = preload("res://layer_panel/layer_popup_menu.gd")
const PaintTextureLayer = preload("res://material/paint_texture_layer.gd")
const TextureLayerStack = preload("res://material/texture_layer_stack.gd")
const MaterialGenerationContext = preload("res://material/material_generation_context.gd")

onready var layer_popup_menu : LayerPopupMenu = $LayerPopupMenu

func _ready() -> void:
	set_column_expand(Column.NAME, false)
	set_column_min_width(Column.NAME, 100)
	GlobalProjectSettings.connect("changed", self, "_on_ProjectSettings_changed")


func _gui_input(event : InputEvent) -> void:
	var button_ev := event as InputEventMouseButton
	var key_ev := event as InputEventKey
	if button_ev and button_ev.button_index == BUTTON_RIGHT and\
			button_ev.pressed:
		var layer = _get_layer_at_position(button_ev.position)
		layer_popup_menu.rect_global_position = button_ev.global_position
		layer_popup_menu.texture_layer = layer
		if layer is MaterialLayer:
			layer_popup_menu.material_layer = layer
		layer_popup_menu.popup()
	elif button_ev and button_ev.button_index == BUTTON_LEFT and\
			button_ev.pressed:
		# `get_selected` returns null the first time a layer is clicked.
		# If it doesn't, in thin case it means the layer was "double clicked".
		if get_selected():
			get_selected().set_editable(Column.NAME, true)
			# If a layer was set editable reset it to not editable again.
			if is_instance_valid(_last_edited_layer):
				_last_edited_layer.set_editable(Column.NAME, false)
			_last_edited_layer = get_selected()
	elif key_ev and key_ev.pressed and key_ev.scancode == KEY_DELETE:
		var layer : Reference = get_selected_layer()
		if not layer:
			return
		undo_redo.create_action("Delete Layer")
		undo_redo.add_do_method(layer_material, "delete_layer",
			layer)
		undo_redo.add_do_method(self, "reload")
		undo_redo.add_undo_method(layer_material, "add_layer",
# warning-ignore:unsafe_property_access
# warning-ignore:unsafe_property_access
			layer, layer.parent)
		undo_redo.add_undo_method(self, "_do_select_layer", layer)
		undo_redo.add_undo_method(self, "reload")
		undo_redo.commit_action()


func get_selected_layer() -> Reference:
	if not get_selected():
		return null
	return get_selected().get_meta("layer")


func expand_layer(layer):
	_layer_states[layer] = LayerState.MAP_EXPANDED


func collapse_layer(layer):
	_layer_states[layer] = LayerState.CLOSED


func _on_cell_selected() -> void:
	_do_select_layer(get_selected().get_meta("layer"))


func _on_button_pressed(item : TreeItem, _column : int, id : int) -> void:
	var layer = item.get_meta("layer")
	match id:
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


func _on_item_edited() -> void:
	if get_edited_column() != 1:
		return
	undo_redo.create_action("Rename Layer")
	var edited_layer = get_edited().get_meta("layer")
	undo_redo.add_do_property(edited_layer, "name", get_edited().get_text(1))
	undo_redo.add_do_method(self, "reload")
	undo_redo.add_undo_method(self, "reload")
	undo_redo.add_undo_property(edited_layer, "name", edited_layer.name)
	undo_redo.add_undo_method(self, "reload")
	undo_redo.commit_action()
	_last_edited_layer = null


func _draw_layer_item(item : TreeItem, item_rect : Rect2) -> void:
	var layer : Reference = item.get_meta("layer")
	if not layer in _layer_states:
		return
	var state : int = _layer_states[layer]
	if not state in [LayerState.MAP_EXPANDED, LayerState.MASK_EXPANDED]:
		return
	var icon_rect := Rect2(Vector2(129, item_rect.position.y), Vector2(32, 32))
	var mat_layer := layer as MaterialLayer
	if mat_layer and mat_layer.mask and state == LayerState.MASK_EXPANDED:
		icon_rect.position.x -= 38
	draw_rect(icon_rect, Color.dodgerblue, false, 2.0)


func get_drag_data(_position : Vector2):
	var selected_layers := []
	var selected = get_next_selected(null)
	if not selected:
		return
	var preview := VBoxContainer.new()
	while selected:
		if selected_layers.empty() or selected.get_script() ==\
				selected_layers[0].get_script():
			selected_layers.append(selected.get_meta("layer"))
			var label = Label.new()
			label.text = selected.get_meta("layer").name
			preview.add_child(label)
		selected = get_next_selected(selected)
#	set_drag_preview(preview)
#	drop_mode_flags = DROP_MODE_INBETWEEN | DROP_MODE_ON_ITEM
#	return {
#		type = "layers",
#		layers = selected_layers,
#	}


func can_drop_data(position : Vector2, data) -> bool:
	var layer_data := _get_layers_of_drop_data(data, position)
	if not layer_data.empty():
		var layers : Array = layer_data.layers
		var to_drop : Reference = layers.front()
		var onto_layer := get_item_at_position(position)
		if onto_layer:
			var onto : Reference = onto_layer.get_meta("layer")
			for layer in layers:
				if layer == onto:
					# Can't drop layer ontop of itself.
					return false
			if get_drop_section_at_position(position) == 0:
				# Allow dropping texture layers onto material layers and
				# material layers onto material layers.
				return (to_drop is TextureLayer and onto is MaterialLayer) or\
						(to_drop is MaterialLayer and onto is MaterialLayer)
			else:
				# Every layer type can be reordered, texture layers can be
				# dropped under material layers.
				return to_drop.get_script() == onto.get_script() or\
						to_drop is TextureLayer
		else:
			# Only material layers can be dropped onto nothing.
			return to_drop is MaterialLayer
	return false


func drop_data(position : Vector2, data) -> void:
	var layer_data := _get_layers_of_drop_data(data, position)
	if layer_data.empty():
		return
	var layers : Array = layer_data.layers
	var onto_layer : Reference = _get_layer_at_position(position)
	var onto : Reference
	var onto_position : int
	match get_drop_section_at_position(position):
		0:
			# Dropped onto layer.
			onto = onto_layer
# warning-ignore:unsafe_property_access
			onto_position = onto_layer.layers.size()
		-100:
			# Dropped onto nothing.
			onto = layer_material
			onto_position = layer_material.layers.size()
		var section:
			# Dropped above/below layer.
			# FIXME: this produces wrong results when droping a layer down.
# warning-ignore:unsafe_property_access
			onto = onto_layer.parent
# warning-ignore:unsafe_property_access
			onto_position = onto.layers.find(onto_layer)
			if section == 1:
				onto_position += 1
# warning-ignore:unsafe_property_access
# warning-ignore:unsafe_property_access
			onto_position = int(clamp(onto_position, 0, onto.layers.size() - 1))
	
	# Add the layers in the reverse order to keep the order intact.
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
			# Delete the old layer.
			undo_redo.add_do_method(layer_mat, "delete_layer", layer, false)
			# Add the new layer.
			undo_redo.add_do_method(layer_mat, "add_layer", new_layer, onto,
					onto_position, false)
			# Delete the new layer.
			undo_redo.add_undo_method(layer_mat, "delete_layer", new_layer,
					false)
			# Restore the old layer.
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


func _do_select_layer(layer : Reference) -> void:
	_is_painting = layer is PaintTextureLayer
	emit_signal("layer_selected", layer)


func _get_layers_of_drop_data(data, _position : Vector2) -> Dictionary:
	var layers : Array
	if data is SmartMaterialAsset:
		layers = [data.data.duplicate()]
	elif data is Dictionary and "type" in data and data.type == "layers":
		layers = data.layers
	else:
		return {}
	return {
		layers = layers,
	}


func set_layer_material(to : MaterialLayerStack) -> void:
	layer_material = to
	if not layer_material.is_connected("results_changed", self,
			"_on_MaterialLayerStack_results_changed"):
		layer_material.connect("results_changed", self,
				"_on_MaterialLayerStack_results_changed")
	var selected_layer = get_selected_layer()
	clear()
	_root = create_item()
	for material_layer in layer_material.layers:
		_setup_material_layer_item(material_layer, _root, selected_layer)


func _on_MaterialLayerStack_results_changed():
	reload()


func _setup_material_layer_item(layer : MaterialLayer, parent_item : TreeItem,
	selected_layer : Reference) -> void:
	var item := create_item(parent_item)
	if layer == selected_layer:
		_select_item(item)
	item.custom_minimum_height = 32
	item.set_meta("layer", layer)
	item.set_text(Column.NAME, layer.name)
	item.add_button(Column.ICONS, _get_visibility_icon(layer.visible),
		Buttons.VISIBILITY)
	item.set_custom_draw(Column.ICONS, self, "_draw_layer_item")
	item.set_cell_mode(Column.ICONS, TreeItem.CELL_MODE_CUSTOM)
	
	item.set_cell_mode(Column.OPACITY, TreeItem.CELL_MODE_RANGE)
	item.set_range_config(Column.OPACITY, 0, 1, 0.01)
	item.set_editable(Column.OPACITY, true)
	item.set_tooltip(Column.OPACITY, "Layer opacity")
	
	if not layer in _layer_states:
		_layer_states[layer] = LayerState.CLOSED
	var state : int = _layer_states[layer]
	
	if layer.mask:
		var icon = _get_layer_texture_icon(layer.mask)
		if icon is GDScriptFunctionState:
			icon = yield(icon, "completed")
		if not is_instance_valid(item):
			return
		if icon is Texture:
			item.add_button(Column.ICONS, icon, Buttons.MASK)
	elif state == LayerState.MASK_EXPANDED:
		_layer_states[layer] = LayerState.CLOSED
	if state in [LayerState.MAP_EXPANDED, LayerState.MASK_EXPANDED]:
		var main_layers := layer.main.layers.duplicate()
		if layer.hide_first_layer:
			main_layers.pop_front()
		for texture_layer in main_layers if state ==\
				LayerState.MAP_EXPANDED else layer.mask.layers:
			_setup_texture_layer_item(texture_layer, item, selected_layer)
	if layer.is_folder:
		var icon := preload("res://icons/large_folder.svg")
		if state == LayerState.FOLDER_EXPANDED:
			icon = preload("res://icons/large_open_folder.svg")
			for sub_layer in layer.layers:
				_setup_material_layer_item(sub_layer, item, selected_layer)
		item.add_button(Column.ICONS, icon, Buttons.ICON)
		item.set_tooltip(Column.NAME, "%s (contains %s layers)" % [layer.name,
				layer.layers.size()])
	else:
		var icon = _get_layer_texture_icon(layer.main)
		while icon is GDScriptFunctionState:
			icon = yield(icon, "completed")
		if not is_instance_valid(item):
			return
		if icon is Texture:
			item.add_button(Column.ICONS, icon, Buttons.RESULT)


func get_selected_layer_texture(layer : MaterialLayer) -> TextureLayerStack:
	return layer.mask if _layer_states[layer] ==\
			LayerState.MASK_EXPANDED else layer.main


func _setup_texture_layer_item(layer : TextureLayer, parent_item : TreeItem,
		selected_layer : Reference) -> void:
	var item := create_item(parent_item)
	if layer == selected_layer:
		_select_item(item)
	item.set_meta("layer", layer)
	item.custom_minimum_height = 16
	
	var layer_name : String
	var layer_visible : bool
	layer_name = layer.name
	layer_visible = layer.visible
	item.set_text(Column.NAME, layer_name)
	item.set_tooltip(Column.NAME, "%s (%s Layer)" % [layer.name,
			layer.get_name()])
	item.add_button(Column.ICONS, _get_visibility_icon(layer_visible),
			Buttons.VISIBILITY)
	
	var icon = _get_texture_layer_icon(layer)
	while icon is GDScriptFunctionState:
		icon = yield(icon, "completed")
	if not is_instance_valid(item):
		return
	if icon is Texture:
		item.add_button(Column.ICONS, icon, Buttons.RESULT)


func _get_visibility_icon(is_visible : bool) -> Texture:
	return preload("res://icons/visible.svg") if is_visible else\
		preload("res://icons/hidden.svg")


func _select_item(item : TreeItem) -> void:
	# Hack to select a `TreeItem` in SelectMode.SELECT_MULTI.
	select_mode = Tree.SELECT_SINGLE
	set_block_signals(true)
	item.select(1)
	select_mode = Tree.SELECT_MULTI
	set_block_signals(false)


func _get_layer_texture_icon(layer : TextureLayerStack) -> Texture:
	if update_icons and not _is_painting:
		var result = layer.get_icon(_selected_map, context)
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
		if not result:
			return preload("res://main/empty_layer_icon.png")
		return result
	return layer.icons.get(_selected_map)


func _get_texture_layer_icon(layer : TextureLayer) -> Texture:
	if update_icons and not _is_painting:
		var result = layer.get_icon(_selected_map, context)
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
		if not result:
			return preload("res://main/empty_layer_icon.png")
		return result
	return layer.icons.get(_selected_map)


func _on_ViewMenuButton_update_icons_toggled() -> void:
	update_icons = not update_icons


func _on_Main_current_file_changed(to : ProjectFile) -> void:
	project = to


func _on_Main_current_layer_material_changed(to : MaterialLayerStack,
		_id : int) -> void:
	set_layer_material(to)


func _on_Main_context_changed(to : MaterialGenerationContext) -> void:
	context = to


func _on_MapOptionButton_map_selected(map : String) -> void:
	_selected_map = map
	reload()


func _on_ProjectSettings_changed() -> void:
#	var selected = GlobalProjectSettings.get_setting("selected_layer")
	# TODO: Load and save tree folding/selection
	pass
