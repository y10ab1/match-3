extends Node2D

var board: Node2D

func _ready() -> void:
	board = get_parent()

func _draw() -> void:
	if board == null or not board.has_method("get_obstacle_map"):
		return
	var offset = board.board_offset
	var w = board.grid_width
	var h = board.grid_height
	var cs = board.cell_size
	var blocked = board.blocked_cells

	var bg_rect = Rect2(offset - Vector2(8, 8), Vector2(w * cs + 16, h * cs + 16))
	draw_rect(bg_rect, Color(0.12, 0.08, 0.2, 0.85), true)
	draw_rect(bg_rect, Color(0.4, 0.3, 0.6, 0.6), false, 3.0)

	for x in w:
		for y in h:
			if Vector2i(x, y) in blocked:
				continue
			var cell_pos = offset + Vector2(x * cs, y * cs)
			var cell_rect = Rect2(cell_pos + Vector2(2, 2), Vector2(cs - 4, cs - 4))
			var shade = Color(0.18, 0.14, 0.28) if (x + y) % 2 == 0 else Color(0.22, 0.17, 0.32)
			draw_rect(cell_rect, shade, true)

	var obs_map = board.get_obstacle_map()
	for pos in obs_map:
		var obs = obs_map[pos]
		var cell_center = offset + Vector2(pos.x * cs + cs / 2.0, pos.y * cs + cs / 2.0)
		match obs["type"]:
			"ice":
				var alpha = 0.15 + obs["hp"] * 0.12
				var ice_rect = Rect2(offset + Vector2(pos.x * cs + 1, pos.y * cs + 1), Vector2(cs - 2, cs - 2))
				draw_rect(ice_rect, Color(0.7, 0.85, 1.0, alpha), true)
				for i in obs["hp"]:
					var inset = 3.0 + i * 4.0
					var r = Rect2(offset + Vector2(pos.x * cs + inset, pos.y * cs + inset), Vector2(cs - inset * 2, cs - inset * 2))
					draw_rect(r, Color(0.8, 0.9, 1.0, 0.3), false, 1.5)
			"wire":
				var wr = Rect2(offset + Vector2(pos.x * cs + 3, pos.y * cs + 3), Vector2(cs - 6, cs - 6))
				draw_rect(wr, Color(0.5, 0.5, 0.5, 0.4), false, 2.5)
				for i in 3:
					var lx = offset.x + pos.x * cs + 3 + (cs - 6) * (i + 1) / 4.0
					draw_line(Vector2(lx, offset.y + pos.y * cs + 3), Vector2(lx, offset.y + pos.y * cs + cs - 3), Color(0.6, 0.6, 0.6, 0.3), 1.0)
				for i in 3:
					var ly = offset.y + pos.y * cs + 3 + (cs - 6) * (i + 1) / 4.0
					draw_line(Vector2(offset.x + pos.x * cs + 3, ly), Vector2(offset.x + pos.x * cs + cs - 3, ly), Color(0.6, 0.6, 0.6, 0.3), 1.0)
			"jelly":
				var jelly_alpha = 0.2 + obs["hp"] * 0.15
				var jr = Rect2(offset + Vector2(pos.x * cs + 1, pos.y * cs + 1), Vector2(cs - 2, cs - 2))
				draw_rect(jr, Color(0.9, 0.3, 0.5, jelly_alpha), true)
