extends "res://viewport/viewport.gd"

var cached_skys := {}

const HDRAssetType = preload("res://asset_browser/asset_classes.gd").HDRAssetType

func _on_HalfResolutionButton_toggled(button_pressed : bool) -> void:
	stretch_shrink = 2 if button_pressed else 1


func can_drop_data(_position : Vector2, data) -> bool:
	return data is Asset and data.type is HDRAssetType


func drop_data(_position : Vector2, data) -> void:
	world_environment.environment.background_sky = get_sky(data.data)


func get_sky(hdr : Image) -> PanoramaSky:
	if hdr in cached_skys:
		return cached_skys[hdr]
	
	var new_sky := PanoramaSky.new()
	var hdr_texture := ImageTexture.new()
	hdr_texture.create_from_image(hdr)
	new_sky.panorama = hdr_texture
	cached_skys[hdr] = new_sky
	return new_sky
