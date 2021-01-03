tool
extends EditorPlugin

"""
A plugin to generate code to preload a node or load a class
"""

var number_regex := RegEx.new()

func _enter_tree() -> void:
	number_regex.compile("\\d\\/*")
	
	add_tool_menu_item("Generate Node Reference", self, "_on_ToolMenu_generate_node_reference_pressed")
	add_tool_menu_item("Generate Class Reference", self, "_on_ToolMenu_generate_class_reference_pressed")
	add_tool_menu_item("Update Node References", self, "_on_ToolMenu_update_node_references_pressed")


func _exit_tree() -> void:
	remove_tool_menu_item("Generate Node Reference")
	remove_tool_menu_item("Generate Class Reference")


func _on_ToolMenu_generate_class_reference_pressed(_ud) -> void:
	var class_script := get_editor_interface().get_script_editor().get_current_script()
	OS.clipboard = "const %s = preload(\"%s\")" % [snake_to_pascal_case(class_script.resource_path.get_file().get_basename()), class_script.resource_path]
	print("Class reference code copied to clipboard")


func _on_ToolMenu_generate_node_reference_pressed(_ud) -> void:
	var selected_nodes := get_editor_interface().get_selection().get_selected_nodes()
	var current_script := get_editor_interface().get_script_editor().get_current_script()
	var relative_to_node := search_node_that_uses(get_editor_interface().get_edited_scene_root(), current_script)
	
	var reference_code := ""
	for selected_node in selected_nodes:
		selected_node = selected_node as Node
		reference_code += get_node_reference(selected_node, relative_to_node.get_path_to(selected_node)) + "\n"
	
	OS.clipboard = reference_code
	print("Node reference code copied to clipboard")


func _on_ToolMenu_update_node_references_pressed(_ud) -> void:
	var updated := ""
	var root := search_node_that_uses(
			get_editor_interface().get_edited_scene_root(),
			get_editor_interface().get_script_editor().get_current_script())
	for assign in OS.clipboard.split("\n", false):
		var node_referenced = get_editor_interface().get_edited_scene_root().\
				find_node(get_node_name(assign))
		if not node_referenced:
			printerr("Can't find node %s" % get_node_name(assign))
		else:
			updated += get_node_reference(
					node_referenced, root.get_path_to(node_referenced)) + "\n"
	OS.clipboard = updated


static func get_node_name(string : String) -> String:
	if not "/" in string:
		return string.substr(string.find("$") + 1)
	return Array(string.replace('"', "").split("/")).back()


static func search_node_that_uses(root : Node, script : Script) -> Node:
	if root.script == script:
		return root
	for node in root.get_children():
		if node.script == script:
			return node
		var found := search_node_that_uses(node, script)
		if found.name != "":
			return found
	return Node.new()


func get_node_reference(to_node : Node, node_path : NodePath) -> String:
	var path := String(node_path)
	if "." in path or number_regex.search(path):
		path = '"%s"' % path
	return "onready var %s : %s = $%s" % [
			pascal_to_snake_case(to_node.name),
			to_node.get_class(),
			path]


static func snake_to_pascal_case(string : String) -> String:
	return string.capitalize().replace(" ", "")


static func pascal_to_snake_case(string : String) -> String:
	# there should be an engine function for this, like with `snake_to_pascal_case`
	var words : PoolStringArray = []
	var word := ""
	for letter_num in string.length():
		var letter := string.substr(letter_num, 1)
		if letter == letter.to_upper() and not word.empty():
			words.append(word)
			word = ""
		word += letter
	words.append(word)
	return words.join("_").to_lower()
