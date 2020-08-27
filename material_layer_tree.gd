extends "res://Tree.gd"

class TextureMap extends Resource:
#	export var 
	pass

class MaterialLayer extends Resource:
	export var mask : Resource
	export var textures : Array
	export var name := "Untitled Layer"


func _on_AddLayerButton_pressed():
	var new_layer := MaterialLayer.new()
	new_layer.name = str(rand_range(1, 20))
	layers.append(new_layer)
	update_tree()
