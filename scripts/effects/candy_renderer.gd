extends Node2D

enum CandyColor { RED, ORANGE, YELLOW, GREEN, BLUE, PURPLE }

const COLOR_MAP = {
	CandyColor.RED: Color(0.95, 0.2, 0.2),
	CandyColor.ORANGE: Color(1.0, 0.55, 0.1),
	CandyColor.YELLOW: Color(1.0, 0.9, 0.15),
	CandyColor.GREEN: Color(0.2, 0.85, 0.3),
	CandyColor.BLUE: Color(0.2, 0.45, 0.95),
	CandyColor.PURPLE: Color(0.7, 0.25, 0.9),
}

const HIGHLIGHT_MAP = {
	CandyColor.RED: Color(1.0, 0.6, 0.6),
	CandyColor.ORANGE: Color(1.0, 0.8, 0.5),
	CandyColor.YELLOW: Color(1.0, 1.0, 0.6),
	CandyColor.GREEN: Color(0.6, 1.0, 0.7),
	CandyColor.BLUE: Color(0.6, 0.75, 1.0),
	CandyColor.PURPLE: Color(0.9, 0.6, 1.0),
}

const SHADOW_MAP = {
	CandyColor.RED: Color(0.55, 0.08, 0.08),
	CandyColor.ORANGE: Color(0.6, 0.3, 0.05),
	CandyColor.YELLOW: Color(0.6, 0.55, 0.05),
	CandyColor.GREEN: Color(0.08, 0.5, 0.12),
	CandyColor.BLUE: Color(0.08, 0.2, 0.55),
	CandyColor.PURPLE: Color(0.35, 0.1, 0.5),
}

static func draw_candy(canvas: CanvasItem, candy_color: int, sz: float, special_type: int = 0) -> void:
	var base = COLOR_MAP[candy_color]
	var highlight = HIGHLIGHT_MAP[candy_color]
	var shadow = SHADOW_MAP[candy_color]
	var half = sz * 0.45

	match candy_color:
		CandyColor.RED:
			_draw_circle_candy(canvas, base, highlight, shadow, half)
		CandyColor.ORANGE:
			_draw_diamond_candy(canvas, base, highlight, shadow, half)
		CandyColor.YELLOW:
			_draw_star_candy(canvas, base, highlight, shadow, half)
		CandyColor.GREEN:
			_draw_square_candy(canvas, base, highlight, shadow, half)
		CandyColor.BLUE:
			_draw_triangle_candy(canvas, base, highlight, shadow, half)
		CandyColor.PURPLE:
			_draw_hexagon_candy(canvas, base, highlight, shadow, half)

	if special_type > 0:
		_draw_special_overlay(canvas, special_type, half, base)

static func _draw_circle_candy(canvas: CanvasItem, base: Color, highlight: Color, shadow: Color, r: float) -> void:
	canvas.draw_circle(Vector2(1, 2), r, shadow * Color(1, 1, 1, 0.4))
	canvas.draw_circle(Vector2.ZERO, r, base)
	canvas.draw_circle(Vector2.ZERO, r * 0.85, lerp(base, highlight, 0.3))
	canvas.draw_circle(Vector2(-r * 0.25, -r * 0.25), r * 0.35, Color(1, 1, 1, 0.45))
	canvas.draw_circle(Vector2(-r * 0.15, -r * 0.15), r * 0.2, Color(1, 1, 1, 0.6))

static func _draw_diamond_candy(canvas: CanvasItem, base: Color, highlight: Color, shadow: Color, r: float) -> void:
	var pts_shadow = PackedVector2Array([
		Vector2(1, -r + 2), Vector2(r + 1, 2), Vector2(1, r + 2), Vector2(-r + 1, 2)
	])
	canvas.draw_colored_polygon(pts_shadow, shadow * Color(1, 1, 1, 0.4))
	var pts = PackedVector2Array([
		Vector2(0, -r), Vector2(r, 0), Vector2(0, r), Vector2(-r, 0)
	])
	canvas.draw_colored_polygon(pts, base)
	var inner = r * 0.75
	var pts_inner = PackedVector2Array([
		Vector2(0, -inner), Vector2(inner, 0), Vector2(0, inner), Vector2(-inner, 0)
	])
	canvas.draw_colored_polygon(pts_inner, lerp(base, highlight, 0.25))
	var shine = PackedVector2Array([
		Vector2(0, -r * 0.7), Vector2(-r * 0.15, -r * 0.2), Vector2(-r * 0.4, -r * 0.15)
	])
	canvas.draw_colored_polygon(shine, Color(1, 1, 1, 0.4))

static func _draw_star_candy(canvas: CanvasItem, base: Color, highlight: Color, shadow: Color, r: float) -> void:
	var pts_outer = _star_points(Vector2(1, 2), r, r * 0.45, 5)
	canvas.draw_colored_polygon(pts_outer, shadow * Color(1, 1, 1, 0.4))
	var pts = _star_points(Vector2.ZERO, r, r * 0.45, 5)
	canvas.draw_colored_polygon(pts, base)
	var pts_inner = _star_points(Vector2.ZERO, r * 0.75, r * 0.35, 5)
	canvas.draw_colored_polygon(pts_inner, lerp(base, highlight, 0.3))
	canvas.draw_circle(Vector2(-r * 0.15, -r * 0.2), r * 0.18, Color(1, 1, 1, 0.5))

static func _draw_square_candy(canvas: CanvasItem, base: Color, highlight: Color, shadow: Color, r: float) -> void:
	var rr = r * 0.85
	canvas.draw_rect(Rect2(Vector2(-rr + 1, -rr + 2), Vector2(rr * 2, rr * 2)), shadow * Color(1, 1, 1, 0.4))
	canvas.draw_rect(Rect2(Vector2(-rr, -rr), Vector2(rr * 2, rr * 2)), base)
	var ir = rr * 0.78
	canvas.draw_rect(Rect2(Vector2(-ir, -ir), Vector2(ir * 2, ir * 2)), lerp(base, highlight, 0.25))
	var shine_pts = PackedVector2Array([
		Vector2(-rr * 0.7, -rr * 0.7), Vector2(-rr * 0.1, -rr * 0.7),
		Vector2(-rr * 0.7, -rr * 0.1)
	])
	canvas.draw_colored_polygon(shine_pts, Color(1, 1, 1, 0.35))

static func _draw_triangle_candy(canvas: CanvasItem, base: Color, highlight: Color, shadow: Color, r: float) -> void:
	var pts_shadow = PackedVector2Array([
		Vector2(1, -r * 0.85 + 2), Vector2(r * 0.9 + 1, r * 0.65 + 2), Vector2(-r * 0.9 + 1, r * 0.65 + 2)
	])
	canvas.draw_colored_polygon(pts_shadow, shadow * Color(1, 1, 1, 0.4))
	var pts = PackedVector2Array([
		Vector2(0, -r * 0.85), Vector2(r * 0.9, r * 0.65), Vector2(-r * 0.9, r * 0.65)
	])
	canvas.draw_colored_polygon(pts, base)
	var s = 0.7
	var pts_inner = PackedVector2Array([
		Vector2(0, -r * 0.85 * s + r * 0.05), Vector2(r * 0.9 * s, r * 0.65 * s + r * 0.05),
		Vector2(-r * 0.9 * s, r * 0.65 * s + r * 0.05)
	])
	canvas.draw_colored_polygon(pts_inner, lerp(base, highlight, 0.3))
	canvas.draw_circle(Vector2(-r * 0.1, -r * 0.15), r * 0.15, Color(1, 1, 1, 0.4))

static func _draw_hexagon_candy(canvas: CanvasItem, base: Color, highlight: Color, shadow: Color, r: float) -> void:
	var pts_shadow = _polygon_points(Vector2(1, 2), r, 6)
	canvas.draw_colored_polygon(pts_shadow, shadow * Color(1, 1, 1, 0.4))
	var pts = _polygon_points(Vector2.ZERO, r, 6)
	canvas.draw_colored_polygon(pts, base)
	var pts_inner = _polygon_points(Vector2.ZERO, r * 0.78, 6)
	canvas.draw_colored_polygon(pts_inner, lerp(base, highlight, 0.25))
	canvas.draw_circle(Vector2(-r * 0.2, -r * 0.2), r * 0.18, Color(1, 1, 1, 0.45))

static func _draw_special_overlay(canvas: CanvasItem, special_type: int, r: float, base_color: Color) -> void:
	match special_type:
		1: # Striped horizontal
			for i in 3:
				var y_off = (i - 1) * r * 0.35
				canvas.draw_line(Vector2(-r * 0.6, y_off), Vector2(r * 0.6, y_off), Color(1, 1, 1, 0.7), 2.0)
		2: # Striped vertical
			for i in 3:
				var x_off = (i - 1) * r * 0.35
				canvas.draw_line(Vector2(x_off, -r * 0.6), Vector2(x_off, r * 0.6), Color(1, 1, 1, 0.7), 2.0)
		3: # Wrapped
			canvas.draw_rect(Rect2(Vector2(-r * 0.3, -r * 0.3), Vector2(r * 0.6, r * 0.6)), Color(1, 1, 1, 0.5), false, 2.5)
			canvas.draw_rect(Rect2(Vector2(-r * 0.5, -r * 0.5), Vector2(r, r)), Color(1, 1, 1, 0.3), false, 1.5)
		4: # Color bomb
			for i in 8:
				var angle = TAU * i / 8.0
				var from_pt = Vector2.ZERO
				var to_pt = Vector2(cos(angle), sin(angle)) * r * 0.7
				var rainbow = Color.from_hsv(float(i) / 8.0, 0.9, 1.0)
				canvas.draw_line(from_pt, to_pt, rainbow, 2.0)
			canvas.draw_circle(Vector2.ZERO, r * 0.25, Color.WHITE)
			canvas.draw_circle(Vector2.ZERO, r * 0.15, Color(0.2, 0.2, 0.2))

static func draw_color_bomb(canvas: CanvasItem, sz: float) -> void:
	var r = sz * 0.45
	canvas.draw_circle(Vector2(1, 2), r, Color(0, 0, 0, 0.3))
	canvas.draw_circle(Vector2.ZERO, r, Color(0.15, 0.15, 0.15))
	canvas.draw_circle(Vector2.ZERO, r * 0.85, Color(0.25, 0.25, 0.25))
	for i in 12:
		var angle = TAU * i / 12.0
		var from_pt = Vector2(cos(angle), sin(angle)) * r * 0.3
		var to_pt = Vector2(cos(angle), sin(angle)) * r * 0.75
		var rainbow = Color.from_hsv(float(i) / 12.0, 1.0, 1.0)
		canvas.draw_line(from_pt, to_pt, rainbow, 2.5)
	canvas.draw_circle(Vector2.ZERO, r * 0.2, Color.WHITE)

static func _star_points(center: Vector2, outer_r: float, inner_r: float, points: int) -> PackedVector2Array:
	var result = PackedVector2Array()
	for i in points * 2:
		var angle = TAU * i / (points * 2) - PI / 2
		var r = outer_r if i % 2 == 0 else inner_r
		result.append(center + Vector2(cos(angle), sin(angle)) * r)
	return result

static func _polygon_points(center: Vector2, r: float, sides: int) -> PackedVector2Array:
	var result = PackedVector2Array()
	for i in sides:
		var angle = TAU * i / sides - PI / 2
		result.append(center + Vector2(cos(angle), sin(angle)) * r)
	return result
