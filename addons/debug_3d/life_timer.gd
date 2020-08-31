extends Timer

func _on_timeout() -> void:
	get_parent().queue_free()
