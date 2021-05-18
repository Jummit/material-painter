extends "res://viewport/viewport.gd"

var blur_amount := 0
var background_visible := false
var hdri := preload("res://viewport/cannon.hdr").get_data()

var cached_skys := {}

const HdriAsset = preload("res://asset_browser/hdri_asset.gd")

onready var texture_rect : TextureRect = $Viewport/SkyViewport/TextureRect
onready var sky_viewport : Viewport = $Viewport/SkyViewport
onready var sky_viewport_texture := sky_viewport.get_texture()

func _ready():
	sky_viewport_texture.flags = Texture.FLAG_FILTER


func _on_ViewMenuButton_show_background_toggled() -> void:
	background_visible = not background_visible
	update_sky()


func can_drop_data(_position : Vector2, data) -> bool:
	return data is Asset and data.type is HdriAsset


func drop_data(_position : Vector2, data : HdriAsset) -> void:
	hdri = data.data
	update_sky()


func get_sky(hdr : Image) -> PanoramaSky:
	if hdr in cached_skys:
		return cached_skys[hdr]
	
	var new_sky := PanoramaSky.new()
	var hdr_texture := ImageTexture.new()
	hdr_texture.create_from_image(hdr)
	new_sky.panorama = hdr_texture
	cached_skys[hdr] = new_sky
	return new_sky


func _on_ViewMenuButton_background_blur_selected(amount : int) -> void:
	blur_amount = amount
	update_sky()


func update_sky() -> void:
	if background_visible:
		world_environment.environment.background_mode = Environment.BG_SKY
	else:
		world_environment.environment.background_mode = Environment.BG_COLOR_SKY
	if blur_amount and background_visible:
		var texture := ImageTexture.new()
		texture.create_from_image(hdri)
		texture_rect.texture = texture
		sky_viewport.size = hdri.get_size() / (blur_amount * 4)
		sky_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
		world_environment.environment.background_sky.panorama = sky_viewport_texture
	else:
		world_environment.environment.background_sky = get_sky(hdri)
