tool
extends EditorScript

# SomeButton

# onready var some_button : Button = $SomeButton

# SomeButton -> some_button

func _run():
	OS.clipboard = ""
	for selected_node in get_editor_interface().get_selection().get_selected_nodes():
		selected_node = selected_node as Node
		var load_code := "onready var %s : %s = $%s" % [
				pascal_to_snake_case(selected_node.name),
				selected_node.get_class(),
				get_editor_interface().get_edited_scene_root().get_path_to(selected_node)]
		print(load_code)
		OS.clipboard += load_code + "\n"

static func pascal_to_snake_case(string : String) -> String:
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
