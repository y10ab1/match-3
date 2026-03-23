extends Node

const CandyScene = preload("res://scripts/candy/candy.gd")

static func find_all_matches(grid: Array, width: int, height: int, blocked: Array[Vector2i] = []) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	var visited: Dictionary = {}

	for y in height:
		for x in width:
			if Vector2i(x, y) in blocked:
				continue
			if grid[x][y] == null:
				continue
			var candy = grid[x][y] as CandyScene
			if candy == null or candy.candy_type == CandyScene.CandyType.COLOR_BOMB:
				continue
			var color = candy.candy_color

			# Horizontal
			var h_cells: Array[Vector2i] = [Vector2i(x, y)]
			var nx = x + 1
			while nx < width and grid[nx][y] != null and not (Vector2i(nx, y) in blocked):
				var nc = grid[nx][y] as CandyScene
				if nc != null and nc.candy_color == color and nc.candy_type != CandyScene.CandyType.COLOR_BOMB:
					h_cells.append(Vector2i(nx, y))
					nx += 1
				else:
					break

			if h_cells.size() >= 3:
				var key = "h_%d_%d_%d" % [y, h_cells[0].x, h_cells[-1].x]
				if not visited.has(key):
					visited[key] = true
					matches.append({"cells": h_cells.duplicate(), "direction": "horizontal"})

			# Vertical
			var v_cells: Array[Vector2i] = [Vector2i(x, y)]
			var ny = y + 1
			while ny < height and grid[x][ny] != null and not (Vector2i(x, ny) in blocked):
				var vc = grid[x][ny] as CandyScene
				if vc != null and vc.candy_color == color and vc.candy_type != CandyScene.CandyType.COLOR_BOMB:
					v_cells.append(Vector2i(x, ny))
					ny += 1
				else:
					break

			if v_cells.size() >= 3:
				var key = "v_%d_%d_%d" % [x, v_cells[0].y, v_cells[-1].y]
				if not visited.has(key):
					visited[key] = true
					matches.append({"cells": v_cells.duplicate(), "direction": "vertical"})

	return _merge_matches(matches)

static func _merge_matches(matches: Array[Dictionary]) -> Array[Dictionary]:
	if matches.size() <= 1:
		return matches

	var merged: Array[Dictionary] = []
	var used: Array[bool] = []
	used.resize(matches.size())
	used.fill(false)

	for i in matches.size():
		if used[i]:
			continue
		var combined_cells: Array[Vector2i] = matches[i]["cells"].duplicate()
		var combined_dirs: Array[String] = [matches[i]["direction"]]
		used[i] = true

		var changed = true
		while changed:
			changed = false
			for j in matches.size():
				if used[j]:
					continue
				var overlap = false
				for cell in matches[j]["cells"]:
					if cell in combined_cells:
						overlap = true
						break
				if overlap:
					for cell in matches[j]["cells"]:
						if not (cell in combined_cells):
							combined_cells.append(cell)
					if not (matches[j]["direction"] in combined_dirs):
						combined_dirs.append(matches[j]["direction"])
					used[j] = true
					changed = true

		var shape = "line"
		if combined_dirs.size() > 1:
			shape = "special"
		elif combined_cells.size() >= 5:
			shape = "five"
		elif combined_cells.size() == 4:
			shape = "four"

		merged.append({
			"cells": combined_cells,
			"shape": shape,
			"directions": combined_dirs
		})

	return merged

static func has_possible_moves(grid: Array, width: int, height: int, blocked: Array[Vector2i] = []) -> bool:
	return find_hint_move(grid, width, height, blocked).size() > 0

static func find_hint_move(grid: Array, width: int, height: int, blocked: Array[Vector2i] = []) -> Array[Vector2i]:
	for y in height:
		for x in width:
			if Vector2i(x, y) in blocked or grid[x][y] == null:
				continue
			for dir in [Vector2i(1, 0), Vector2i(0, 1)]:
				var nx = x + dir.x
				var ny = y + dir.y
				if nx >= width or ny >= height:
					continue
				if Vector2i(nx, ny) in blocked or grid[nx][ny] == null:
					continue
				_swap_in_grid(grid, x, y, nx, ny)
				var found = find_all_matches(grid, width, height, blocked).size() > 0
				_swap_in_grid(grid, x, y, nx, ny)
				if found:
					return [Vector2i(x, y), Vector2i(nx, ny)]
	return []

static func _swap_in_grid(grid: Array, x1: int, y1: int, x2: int, y2: int) -> void:
	var temp = grid[x1][y1]
	grid[x1][y1] = grid[x2][y2]
	grid[x2][y2] = temp
