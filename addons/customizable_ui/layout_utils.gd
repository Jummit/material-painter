"""
Utility to save and load layouts as json files
"""

static func save_layout(root : Container, layout_file : String) -> void:
	var layout := {
		windows = _store_layout(root),
		popped_out = []
	}
	
	for window in root.get_tree().get_nodes_in_group("Windows"):
		if window.get_parent() is WindowDialog:
			layout.popped_out.append({
				x = window.get_parent().rect_position.x,
				y = window.get_parent().rect_position.y,
				width = window.get_parent().rect_size.x,
				height = window.get_parent().rect_size.y,
				window = window.original_path,
			})
	
	var file := File.new()
	file.open(layout_file, File.WRITE)
	file.store_string(to_json(layout))
	file.close()


static func load_layout(root : Node, layout_file : String) -> void:
	var file := File.new()
	file.open(layout_file, File.READ)
	var layout : Dictionary = parse_json(file.get_as_text())
	file.close()
	
	var windows := {}
	for window in root.get_tree().get_nodes_in_group("Windows"):
		if window.get_parent() is WindowDialog:
			window.get_parent().queue_free()
		window.get_parent().remove_child(window)
		windows[String(window.original_path)] = window
	
	for popped_out in layout.popped_out:
		var window_dialog : WindowDialog =\
				windows[popped_out.window].put_in_window()
		window_dialog.rect_position = Vector2(popped_out.x, popped_out.y)
		window_dialog.rect_size = Vector2(popped_out.width, popped_out.height)
	
	_remove_containers(root)
	_load_individual_layout(root, layout.windows, windows)


static func _store_layout(root : Container) -> Dictionary:
	var layout := {
		type = root.get_class(),
		children = []
	}
	if root is SplitContainer:
		layout.split = root.split_offset
	
	for node in root.get_children():
		if node is Panel:
			layout.children.append({
					path = node.original_path,
					visible = node.visible,
				})
		else:
			layout.children.append(_store_layout(node))
	
	return layout


static func _remove_containers(root : Node) -> void:
	for child in root.get_children():
		if child is Container:
			root.remove_child(child)
			_remove_containers(child)


static func _load_individual_layout(root : Node, layout : Dictionary,
		windows : Dictionary) -> void:
	var container : Container = ClassDB.instance(layout.type)
	container.anchor_right = 1
	container.anchor_bottom = 1
	for window in layout.children:
		if "path" in window:
			container.add_child(windows[window.path])
			windows[window.path].visible = window.visible
		else:
			_load_individual_layout(container, window, windows)
	root.add_child(container)
	if container is SplitContainer:
		container.split_offset = layout.split
