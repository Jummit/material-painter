tool
extends VBoxContainer

"""
A list of buttons used to select the painting tool

Procedurally adds buttons and loads icons from `res://icons/tools/`.
Only shows when a `BitmapTextureLayer` is selected.
"""

signal tool_selected(tool_id)

const BitmapTextureLayer = preload("res://layers/texture_layers/bitmap_texture_layer.gd")

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


func _on_LayerTree_texture_layer_selected(texture_layer):
	visible = texture_layer is BitmapTextureLayer


func _on_LayerTree_cell_selected():
	hide()
