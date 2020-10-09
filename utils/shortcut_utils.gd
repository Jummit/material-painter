static func shortcut(keycode : int) -> ShortCut:
	var shortcut := ShortCut.new()
	var event := InputEventKey.new()
	event.pressed = true
	event.scancode = keycode & KEY_CODE_MASK
	event.unicode = keycode & KEY_CODE_MASK
	event.shift = keycode & KEY_MASK_SHIFT
	event.control = keycode & KEY_MASK_CTRL
	event.alt = keycode & KEY_MASK_ALT
	shortcut.shortcut = event
	return shortcut
