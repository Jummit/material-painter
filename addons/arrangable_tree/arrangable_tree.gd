extends Tree

var layers := []

func get_drag_data(position : Vector2):
	var preview = Label.new()
	preview.text = get_selected().get_text(0)
	set_drag_preview(preview)
	return get_item_at_position(position)


func can_drop_data(_position : Vector2, data) -> bool:
	drop_mode_flags = DROP_MODE_INBETWEEN
	return data is TreeItem


func drop_data(position : Vector2, data) -> void:
	var relative_to := _get_item_index(get_item_at_position(position))
	var motion := get_drop_section_at_position(position)
	if motion == -1:
		motion = 0
	var tree_item_to_move := data as TreeItem
	# TODO: fix this
	layers.insert(int(clamp(relative_to + motion, 0, layers.size())), tree_item_to_move.get_metadata(0).duplicate())
	layers.erase(tree_item_to_move.get_metadata(0))
	update_tree()


func update_tree() -> void:
	clear()
	var root = create_item()
	for layer in layers:
		var layer_item := create_item(root)
		layer_item.set_metadata(0, layer)
		setup_item(layer_item, layer)


func _get_item_index(item : TreeItem) -> int:
	var index := 0
	var tree_item := get_root().get_children()
	while true:
		if tree_item == item:
			break
		index += 1
		tree_item = tree_item.get_next_visible()
	return index


func _on_item_activated():
	var tex


func setup_item(layer_item : TreeItem, layer) -> void:
	pass
