tool
extends VBoxContainer

signal tool_selected(tool_id)

onready var main : Control = $"../../../../../../.."

func _ready():
	for tool_name in main.Tools:
		var tool_button := Button.new()
		tool_button.name = tool_name
		tool_button.connect("pressed", self, "_on_ToolButton_pressed", [main.Tools[tool_name]])
		tool_button.icon = load("res://icons/tools/%s.svg" % tool_name.to_lower())
		add_child(tool_button)


func _on_ToolButton_pressed(tool_id : int):
	emit_signal("tool_selected", tool_id)
