extends VBoxContainer

# todo: move this to the TextureLayerTree

"""
Droping textures onto the `TextureLayerPanel` creates a `BitmapTextureLayer`.
"""

onready var texture_layer_tree : Tree = $TextureLayerTree
onready var main := $"../../../.."

const BitmapTextureLayer = preload("res://texture_layers/types/bitmap_texture_layer.gd")

func _ready() -> void:
	texture_layer_tree.set_drag_forwarding(self)


func can_drop_data_fw(_position : Vector2, data, _from_control : Control) -> bool:
	return data is String


func drop_data_fw(_position : Vector2, data : String, _from_control : Control) -> void:
	var texture_layer := BitmapTextureLayer.new(data.get_file().get_basename())
	texture_layer.properties.image_path = data
	main.add_texture_layer(texture_layer)
