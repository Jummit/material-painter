extends GridContainer

"""
A list of buttons used to select the painting/selection tool

Procedurally adds buttons and loads icons from `res://icons/tools/`.
Only shows when a `BitmapTextureLayer` is selected.
"""

signal tool_selected(selected)

const PaintTextureLayer = preload("res://material/paint_texture_layer.gd")
const Constants = preload("res://main/constants.gd")

func _ready() -> void:
	for tool_name in Constants.Tools:
		var tool_button := Button.new()
		tool_button.name = tool_name
		tool_button.connect("pressed", self, "_on_ToolButton_pressed",
				[Constants.Tools[tool_name]])
		tool_button.icon = load("res://icons/tools/%s.svg" % tool_name.to_lower())
		add_child(tool_button)


func _on_ToolButton_pressed(tool_id : int) -> void:
	emit_signal("tool_selected", tool_id)


func _on_LayerTree_layer_selected(layer) -> void:
	(get_parent() as CanvasItem).visible = layer is PaintTextureLayer


func _on_resized() -> void:
	columns = int((get_parent() as Control).rect_size.x / 46.0)
