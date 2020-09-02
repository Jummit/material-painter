tool
extends EditorPlugin

# todo: make root references work

func _enter_tree() -> void:
	add_tool_menu_item("Generate Node Reference", self, "_on_ToolMenu_generate_node_reference_pressed")
	add_tool_menu_item("Generate Class Reference", self, "_on_ToolMenu_generate_class_reference_pressed")


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
	
#	current_script.source_code = current_script.source_code.insert(get_onready_position(current_script.source_code), reference_code)
#	ResourceSaver.save(current_script.resource_path, current_script)
#	get_editor_interface().get_resource_filesystem().update_file(current_script.resource_path)
	
	OS.clipboard = reference_code
	print("Node reference code copied to clipboard")


static func get_onready_position(code : String) -> int:
	var last_preload := code.find_last("preload")
	if last_preload == -1:
		return code.find("\n") + 1
	return code.findn("\n", last_preload) + 1


static func search_node_that_uses(root : Node, script : Script) -> Node:
	for node in root.get_children():
		if node.script == script:
			return node
		var found := search_node_that_uses(node, script)
		if found.name != "":
			return found
	return Node.new()


static func get_node_reference(to_node : Node, node_path : NodePath) -> String:
	return "onready var %s : %s = $\"%s\"" % [
			pascal_to_snake_case(to_node.name),
			to_node.get_class(),
			node_path]


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
