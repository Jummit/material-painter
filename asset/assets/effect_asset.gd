extends "asset.gd"

func _init(_path).(_path) -> void:
	pass


func _load_data() -> void:
	var file := File.new()
	file.open(path, File.READ)
	data = parse_json(file.get_as_text())


static func get_type() -> String:
	return "effect"


func show_in_menu() -> bool:
	return data.get("show_in_menu", false)
