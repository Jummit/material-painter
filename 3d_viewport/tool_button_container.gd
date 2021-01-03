extends VBoxContainer

"""
A list of buttons used to select the painting/selection tool

Procedurally adds buttons and loads icons from `res://icons/tools/`.
Only shows when a `BitmapTextureLayer` is selected.
"""

signal tool_selected(tool_id)

const BitmapTextureLayer = preload("res://resources/texture/layers/bitmap_texture_layer.gd")

func _ready() -> void:
	for tool_name in Globals.Tools:
		var tool_button := Button.new()
		tool_button.name = tool_name
		tool_button.pressed = Globals.selected_tool == Globals.Tools[tool_name]
		tool_button.connect("pressed", self, "_on_ToolButton_pressed", [Globals.Tools[tool_name]])
		tool_button.icon = load("res://icons/tools/%s.svg" % tool_name.to_lower())
		add_child(tool_button)


func _on_LayerTree_texture_layer_selected(texture_layer) -> void:
	get_parent().visible = texture_layer is BitmapTextureLayer
	if texture_layer is BitmapTextureLayer:
		emit_signal("tool_selected", Globals.selected_tool)


func _on_LayerTree_cell_selected() -> void:
	get_parent().hide()


func _on_ToolButton_pressed(tool_id : int) -> void:
	if tool_id != Globals.selected_tool:
		Globals.selected_tool = tool_id
		emit_signal("tool_selected", tool_id)
