extends Node2D

const MatchFinder = preload("res://scripts/board/match_finder.gd")
const CandyScript = preload("res://scripts/candy/candy.gd")

@export var grid_width: int = 9
@export var grid_height: int = 9
@export var cell_size: float = 70.0

@onready var candy_container: Node2D = $CandyContainer
@onready var board_bg: Node2D = $BoardBG
@onready var filler_node: Node = $BoardFiller
@onready var effect_spawner_node: Node2D = $EffectSpawner

var candy_scene: PackedScene = preload("res://scenes/candy.tscn")
var filler: Node
var board_offset: Vector2 = Vector2.ZERO
var blocked_cells: Array[Vector2i] = []
var obstacle_map: Dictionary = {}

var selected_candy: CandyScript = null
var is_processing: bool = false
var cascade_level: int = 0

var _hint_timer: float = 0.0
var _hint_delay: float = 3.0
var _hint_candies: Array = []
var _hint_shown: bool = false

signal board_ready
signal turn_completed
signal candies_destroyed(count: int, color: int)

func _ready() -> void:
	_calculate_offset()

func _process(delta: float) -> void:
	if filler == null or is_processing or _hint_shown:
		return
	_hint_timer += delta
	if _hint_timer >= _hint_delay:
		_show_hint()

func _reset_hint_timer() -> void:
	_hint_timer = 0.0
	if _hint_shown:
		_clear_hint()

func _show_hint() -> void:
	var move = MatchFinder.find_hint_move(filler.grid, grid_width, grid_height, blocked_cells)
	if move.size() < 2:
		return
	_hint_shown = true
	for pos in move:
		var candy = filler.get_candy_at(pos)
		if candy and is_instance_valid(candy):
			candy.play_hint()
			_hint_candies.append(candy)

func _clear_hint() -> void:
	for candy in _hint_candies:
		if is_instance_valid(candy):
			candy.stop_hint()
	_hint_candies.clear()
	_hint_shown = false

func _calculate_offset() -> void:
	var board_width = grid_width * cell_size
	var board_height = grid_height * cell_size
	var viewport_size = get_viewport_rect().size
	board_offset = Vector2(
		(viewport_size.x - board_width) / 2.0,
		(viewport_size.y - board_height) / 2.0 + 60
	)
	position = Vector2.ZERO

func init_board(level_data: Resource = null) -> void:
	_clear_board()
	if level_data:
		grid_width = level_data.grid_width
		grid_height = level_data.grid_height
		blocked_cells = level_data.blocked_cells.duplicate()
	_calculate_offset()
	filler = filler_node
	filler.setup(grid_width, grid_height, cell_size, board_offset, candy_container, candy_scene, blocked_cells)
	if level_data and level_data.num_colors > 0:
		filler.num_colors = level_data.num_colors
	_draw_board_background()
	filler.fill_initial()
	_connect_candy_signals()

	var retry_count = 0
	while MatchFinder.find_all_matches(filler.grid, grid_width, grid_height, blocked_cells).size() > 0 and retry_count < 50:
		_clear_board()
		filler.setup(grid_width, grid_height, cell_size, board_offset, candy_container, candy_scene, blocked_cells)
		if level_data and level_data.num_colors > 0:
			filler.num_colors = level_data.num_colors
		filler.fill_initial()
		_connect_candy_signals()
		retry_count += 1

	board_ready.emit()

func _clear_board() -> void:
	for child in candy_container.get_children():
		child.queue_free()

func _draw_board_background() -> void:
	board_bg.queue_redraw()

func _connect_candy_signals() -> void:
	for x in grid_width:
		for y in grid_height:
			var candy = filler.get_candy_at(Vector2i(x, y))
			if candy:
				_connect_single_candy(candy)

func _connect_single_candy(candy: CandyScript) -> void:
	if not candy.candy_selected.is_connected(_on_candy_selected):
		candy.candy_selected.connect(_on_candy_selected)
	if not candy.candy_swipe.is_connected(_on_candy_swiped):
		candy.candy_swipe.connect(_on_candy_swiped)

func _on_candy_selected(candy: CandyScript) -> void:
	if is_processing:
		return
	_reset_hint_timer()

	if selected_candy == null:
		selected_candy = candy
		candy.set_selected(true)
		return

	if selected_candy == candy:
		selected_candy.set_selected(false)
		selected_candy = null
		return

	var dist = (candy.grid_pos - selected_candy.grid_pos).abs()
	if (dist.x == 1 and dist.y == 0) or (dist.x == 0 and dist.y == 1):
		_try_swap(selected_candy, candy)
	else:
		selected_candy.set_selected(false)
		selected_candy = candy
		candy.set_selected(true)

func _on_candy_swiped(candy: CandyScript, direction: Vector2i) -> void:
	if is_processing:
		return
	_reset_hint_timer()
	var target_pos = candy.grid_pos + direction
	if target_pos.x < 0 or target_pos.x >= grid_width or target_pos.y < 0 or target_pos.y >= grid_height:
		return
	if Vector2i(target_pos.x, target_pos.y) in blocked_cells:
		return
	var target_candy = filler.get_candy_at(target_pos)
	if target_candy == null:
		return
	if _is_candy_locked(candy.grid_pos) or _is_candy_locked(target_pos):
		return
	if selected_candy:
		selected_candy.set_selected(false)
		selected_candy = null
	_try_swap(candy, target_candy)

func _is_candy_locked(pos: Vector2i) -> bool:
	if obstacle_map.has(pos):
		var obs = obstacle_map[pos]
		if obs.has("type") and obs["type"] == "wire":
			return true
	return false

func _try_swap(candy_a: CandyScript, candy_b: CandyScript) -> void:
	is_processing = true
	_reset_hint_timer()
	if selected_candy:
		selected_candy.set_selected(false)
		selected_candy = null
	AudioManager.play_swap_sound()

	var pos_a = candy_a.grid_pos
	var pos_b = candy_b.grid_pos
	var world_a = filler.grid_to_world(pos_a)
	var world_b = filler.grid_to_world(pos_b)

	filler.set_candy_at(pos_a, candy_b)
	filler.set_candy_at(pos_b, candy_a)
	candy_a.grid_pos = pos_b
	candy_b.grid_pos = pos_a

	var tween_a = candy_a.animate_to(world_b, 0.2)
	candy_b.animate_to(world_a, 0.2)
	await tween_a.finished

	if candy_a.candy_type == CandyScript.CandyType.COLOR_BOMB or candy_b.candy_type == CandyScript.CandyType.COLOR_BOMB:
		_handle_color_bomb_swap(candy_a, candy_b)
		return

	var matches = MatchFinder.find_all_matches(filler.grid, grid_width, grid_height, blocked_cells)
	if matches.size() == 0:
		AudioManager.play_swap_back_sound()
		filler.set_candy_at(pos_a, candy_a)
		filler.set_candy_at(pos_b, candy_b)
		candy_a.grid_pos = pos_a
		candy_b.grid_pos = pos_b
		var tween_back = candy_a.animate_to(world_a, 0.2)
		candy_b.animate_to(world_b, 0.2)
		await tween_back.finished
		is_processing = false
		return

	GameManager.use_move()
	cascade_level = 0
	await _process_matches(matches)
	_post_turn_check()

func _handle_color_bomb_swap(candy_a: CandyScript, candy_b: CandyScript) -> void:
	GameManager.use_move()
	cascade_level = 0
	var target_color = -1
	var bomb: CandyScript = null
	var other: CandyScript = null

	if candy_a.candy_type == CandyScript.CandyType.COLOR_BOMB:
		bomb = candy_a
		other = candy_b
	else:
		bomb = candy_b
		other = candy_a

	target_color = other.candy_color
	AudioManager.play_special_trigger_sound()

	var to_destroy: Array[Vector2i] = [bomb.grid_pos]
	if other.candy_type == CandyScript.CandyType.COLOR_BOMB:
		for x in grid_width:
			for y in grid_height:
				var c = filler.get_candy_at(Vector2i(x, y))
				if c != null:
					to_destroy.append(Vector2i(x, y))
	else:
		for x in grid_width:
			for y in grid_height:
				var c = filler.get_candy_at(Vector2i(x, y))
				if c != null and c.candy_color == target_color:
					to_destroy.append(Vector2i(x, y))

	for pos in to_destroy:
		var c = filler.get_candy_at(pos)
		if c:
			_trigger_obstacle_adjacent(pos)
			effect_spawner_node.spawn_destroy_effect(filler.grid_to_world(pos), c.candy_color)
			filler.remove_candy_at(pos)
			c.animate_destroy()
			GameManager.add_score(1, true)
			candies_destroyed.emit(1, target_color)

	await get_tree().create_timer(0.3).timeout
	await _cascade_loop()
	_post_turn_check()

func _process_matches(matches: Array[Dictionary]) -> void:
	for match_data in matches:
		var cells = match_data["cells"] as Array[Vector2i]
		var shape = match_data.get("shape", "line")
		var first_candy = filler.get_candy_at(cells[0])
		var match_color = first_candy.candy_color if first_candy else 0

		AudioManager.play_match_sound(cascade_level)
		GameManager.increment_combo()

		var special_pos = cells[0]
		var special_type = -1

		if shape == "five" or cells.size() >= 5:
			special_type = CandyScript.CandyType.COLOR_BOMB
		elif shape == "special":
			special_type = CandyScript.CandyType.WRAPPED
		elif shape == "four" or cells.size() == 4:
			if match_data.get("directions", ["horizontal"])[0] == "horizontal":
				special_type = CandyScript.CandyType.STRIPED_V
			else:
				special_type = CandyScript.CandyType.STRIPED_H

		for cell in cells:
			var candy = filler.get_candy_at(cell)
			if candy:
				if candy.candy_type != CandyScript.CandyType.NORMAL and candy.candy_type != CandyScript.CandyType.COLOR_BOMB:
					_trigger_special_candy(candy)
				_trigger_obstacle_adjacent(cell)
				effect_spawner_node.spawn_destroy_effect(filler.grid_to_world(cell), candy.candy_color)
				GameManager.update_objective("collect", candy.candy_color, 1)
				candies_destroyed.emit(1, candy.candy_color)
				filler.remove_candy_at(cell)
				candy.animate_destroy()

		GameManager.add_score(cells.size(), special_type >= 0)

		if special_type >= 0:
			var color_for_special = match_color
			if special_type == CandyScript.CandyType.COLOR_BOMB:
				color_for_special = -1
			AudioManager.play_special_create_sound()
			filler.create_special_candy(
				match_color if special_type != CandyScript.CandyType.COLOR_BOMB else 0,
				special_pos,
				special_type
			)
			var new_candy = filler.get_candy_at(special_pos)
			if new_candy:
				_connect_single_candy(new_candy)

	await get_tree().create_timer(0.25).timeout
	await _cascade_loop()

func _cascade_loop() -> void:
	var gravity_tweens = filler.apply_gravity()
	if gravity_tweens.size() > 0:
		for tw in gravity_tweens:
			if tw.is_running():
				await tw.finished
		await get_tree().create_timer(0.05).timeout

	var fill_tweens = filler.fill_empty_cells()
	if fill_tweens.size() > 0:
		for x in grid_width:
			for y in grid_height:
				var c = filler.get_candy_at(Vector2i(x, y))
				if c:
					_connect_single_candy(c)
		for tw in fill_tweens:
			if tw.is_running():
				await tw.finished
		await get_tree().create_timer(0.1).timeout

	var new_matches = MatchFinder.find_all_matches(filler.grid, grid_width, grid_height, blocked_cells)
	if new_matches.size() > 0:
		cascade_level += 1
		AudioManager.play_cascade_sound(cascade_level)
		await _process_matches(new_matches)

func _trigger_special_candy(candy: CandyScript) -> void:
	var pos = candy.grid_pos
	match candy.candy_type:
		CandyScript.CandyType.STRIPED_H:
			AudioManager.play_special_trigger_sound()
			for x in grid_width:
				if x != pos.x:
					var target = filler.get_candy_at(Vector2i(x, pos.y))
					if target and not target.is_being_destroyed:
						_trigger_obstacle_adjacent(Vector2i(x, pos.y))
						effect_spawner_node.spawn_destroy_effect(filler.grid_to_world(Vector2i(x, pos.y)), target.candy_color)
						filler.remove_candy_at(Vector2i(x, pos.y))
						target.animate_destroy()
						GameManager.add_score(1, true)

		CandyScript.CandyType.STRIPED_V:
			AudioManager.play_special_trigger_sound()
			for y in grid_height:
				if y != pos.y:
					var target = filler.get_candy_at(Vector2i(pos.x, y))
					if target and not target.is_being_destroyed:
						_trigger_obstacle_adjacent(Vector2i(pos.x, y))
						effect_spawner_node.spawn_destroy_effect(filler.grid_to_world(Vector2i(pos.x, y)), target.candy_color)
						filler.remove_candy_at(Vector2i(pos.x, y))
						target.animate_destroy()
						GameManager.add_score(1, true)

		CandyScript.CandyType.WRAPPED:
			AudioManager.play_special_trigger_sound()
			effect_spawner_node.spawn_shockwave(filler.grid_to_world(pos))
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var tp = Vector2i(pos.x + dx, pos.y + dy)
					var target = filler.get_candy_at(tp)
					if target and not target.is_being_destroyed:
						_trigger_obstacle_adjacent(tp)
						effect_spawner_node.spawn_destroy_effect(filler.grid_to_world(tp), target.candy_color)
						filler.remove_candy_at(tp)
						target.animate_destroy()
						GameManager.add_score(1, true)

func _trigger_obstacle_adjacent(pos: Vector2i) -> void:
	for dir in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
		var adj = pos + dir
		if obstacle_map.has(adj):
			_damage_obstacle(adj)
	if obstacle_map.has(pos):
		var obs = obstacle_map[pos]
		if obs["type"] == "jelly":
			_damage_obstacle(pos)

func _damage_obstacle(pos: Vector2i) -> void:
	if not obstacle_map.has(pos):
		return
	var obs = obstacle_map[pos]
	obs["hp"] -= 1
	AudioManager.play_obstacle_break_sound()
	if obs["hp"] <= 0:
		obstacle_map.erase(pos)
		GameManager.update_objective("clear_" + obs["type"], -1, 1)
	board_bg.queue_redraw()

func _post_turn_check() -> void:
	GameManager.reset_combo()
	_reset_hint_timer()

	if GameManager.check_win_condition():
		GameManager.complete_level()
		is_processing = false
		turn_completed.emit()
		return

	if GameManager.check_lose_condition():
		GameManager.fail_level()
		is_processing = false
		turn_completed.emit()
		return

	if not MatchFinder.has_possible_moves(filler.grid, grid_width, grid_height, blocked_cells):
		await _shuffle_board()

	is_processing = false
	turn_completed.emit()

func _shuffle_board() -> void:
	var candies: Array = []
	for x in grid_width:
		for y in grid_height:
			if filler.get_candy_at(Vector2i(x, y)) != null:
				candies.append(filler.get_candy_at(Vector2i(x, y)))

	candies.shuffle()
	var idx = 0
	for x in grid_width:
		for y in grid_height:
			if Vector2i(x, y) in blocked_cells:
				continue
			if idx < candies.size():
				filler.set_candy_at(Vector2i(x, y), candies[idx])
				candies[idx].grid_pos = Vector2i(x, y)
				candies[idx].animate_to(filler.grid_to_world(Vector2i(x, y)), 0.3)
				idx += 1

	await get_tree().create_timer(0.4).timeout

	if MatchFinder.find_all_matches(filler.grid, grid_width, grid_height, blocked_cells).size() > 0:
		cascade_level = 0
		var matches = MatchFinder.find_all_matches(filler.grid, grid_width, grid_height, blocked_cells)
		await _process_matches(matches)

func set_obstacle_map(obs: Dictionary) -> void:
	obstacle_map = obs
	board_bg.queue_redraw()

func get_obstacle_map() -> Dictionary:
	return obstacle_map
