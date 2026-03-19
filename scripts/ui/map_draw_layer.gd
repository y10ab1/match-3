extends Node2D

var map_parent: Control

func _ready() -> void:
	map_parent = get_parent() as Control

func _draw() -> void:
	if map_parent == null or map_parent.level_positions.size() == 0:
		return

	for i in range(map_parent.level_positions.size() - 1):
		var from_pos = map_parent.level_positions[i]
		var to_pos = map_parent.level_positions[i + 1]
		var unlocked = SaveManager.is_level_unlocked(i + 1)
		var color = Color(0.5, 0.4, 0.7) if unlocked else Color(0.25, 0.2, 0.35)
		draw_line(from_pos, to_pos, color, map_parent.PATH_WIDTH)

	for i in map_parent.level_positions.size():
		var pos = map_parent.level_positions[i]
		var level_id = i + 1
		var unlocked = SaveManager.is_level_unlocked(level_id)
		var stars = SaveManager.get_level_stars(level_id)

		if unlocked:
			draw_circle(pos, map_parent.NODE_RADIUS + 3, Color(0.9, 0.75, 0.3, 0.5))
			var hue = fmod(float(i) * 0.1, 1.0)
			draw_circle(pos, map_parent.NODE_RADIUS, Color.from_hsv(hue, 0.6, 0.9))
		else:
			draw_circle(pos, map_parent.NODE_RADIUS, Color(0.3, 0.25, 0.4))

		var font = ThemeDB.fallback_font
		var font_size = 20
		var num_text = str(level_id)
		var text_size = font.get_string_size(num_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var font_color = Color.WHITE if unlocked else Color(0.5, 0.5, 0.5)
		draw_string(font, pos - Vector2(text_size.x / 2.0, -font_size / 3.0), num_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, font_color)

		if stars > 0:
			var star_text = ""
			for s in 3:
				star_text += "★" if s < stars else "☆"
			var star_sz = font.get_string_size(star_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
			draw_string(font, pos + Vector2(-star_sz.x / 2.0, map_parent.NODE_RADIUS + 18), star_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GOLD)
