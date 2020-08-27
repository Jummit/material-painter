extends Tree

class TextureMap:
	pass

class Layer:
	var masks := []
	var name := "Untitled Layer"

class Mask:
	var texture : TextureMap
	var name := "Untitled Mask"

var layers := []

func update_tree() -> void:
	clear()
	var root = create_item()
	for layer in layers:
		layer = layer as Layer
		var layer_item := create_item(root)
		layer_item.set_metadata(0, layer)
		layer_item.set_text(0, layer.name)
		for mask in layer.masks:
			mask = mask as Mask
			var mask_item := create_item(layer_item)
			mask_item.set_metadata(0, mask)
			mask_item.set_text(0, mask.name)


func _on_AddLayerButton_pressed():
	layers.append(Layer.new())
	update_tree()


func _on_AddMaskButton_pressed():
	if get_selected() and get_selected().get_metadata(0) is Layer:
		(get_selected().get_metadata(0) as Layer).masks.append(Mask.new())
		update_tree()
