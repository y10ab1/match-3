extends CanvasLayer

@onready var score_label: Label = $TopBar/ScoreLabel
@onready var moves_label: Label = $TopBar/MovesLabel
@onready var objective_label: Label = $TopBar/ObjectiveLabel
@onready var score_bar: ProgressBar = $TopBar/ScoreBar
@onready var star1: Node2D = $TopBar/ScoreBar/Star1
@onready var star2: Node2D = $TopBar/ScoreBar/Star2
@onready var star3: Node2D = $TopBar/ScoreBar/Star3

var star_thresholds: Array[int] = []
var _score_objective_target: int = 0
var _star_colors: Array[Color] = [Color(0.4, 0.4, 0.4), Color(0.4, 0.4, 0.4), Color(0.4, 0.4, 0.4)]

func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.moves_changed.connect(_on_moves_changed)
	GameManager.objective_updated.connect(_on_objective_updated)
	star1.draw.connect(func(): _draw_star(star1, 0))
	star2.draw.connect(func(): _draw_star(star2, 1))
	star3.draw.connect(func(): _draw_star(star3, 2))

func setup(level_data: Resource) -> void:
	star_thresholds = level_data.star_thresholds.duplicate()
	if star_thresholds.size() >= 3:
		score_bar.max_value = star_thresholds[2]
	_score_objective_target = 0
	for obj in level_data.objectives:
		if obj.get("type", "") == "score":
			_score_objective_target = obj.get("target", 0)
	_on_score_changed(0)
	_on_moves_changed(level_data.max_moves)
	_update_objective_display(level_data.objectives)

func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score: %d" % new_score
	score_bar.value = new_score
	_update_stars(new_score)
	_animate_score_pop()
	if _score_objective_target > 0:
		objective_label.text = "Score: %d / %d" % [new_score, _score_objective_target]

func _on_moves_changed(remaining: int) -> void:
	moves_label.text = "Moves: %d" % remaining
	if remaining <= 5:
		moves_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		moves_label.add_theme_color_override("font_color", Color.WHITE)

func _on_objective_updated(obj: Dictionary) -> void:
	var current = obj.get("current", 0)
	var target = obj.get("target", 0)
	var type = obj.get("type", "")
	var text = ""
	match type:
		"score":
			text = "Score: %d / %d" % [current, target]
		"collect":
			text = "Collect: %d / %d" % [current, target]
		"clear_jelly":
			text = "Jelly: %d / %d" % [current, target]
		"clear_ice":
			text = "Ice: %d / %d" % [current, target]
	objective_label.text = text

func _update_objective_display(objectives: Array) -> void:
	if objectives.size() == 0:
		objective_label.text = ""
		return
	var obj = objectives[0]
	var target = obj.get("target", 0)
	match obj.get("type", ""):
		"score":
			objective_label.text = "Score: 0 / %d" % target
		"collect":
			objective_label.text = "Collect: 0 / %d" % target
		"clear_jelly":
			objective_label.text = "Jelly: 0 / %d" % target
		"clear_ice":
			objective_label.text = "Ice: 0 / %d" % target

func _update_stars(score: int) -> void:
	if star_thresholds.size() < 3:
		return
	_star_colors[0] = Color.GOLD if score >= star_thresholds[0] else Color(0.4, 0.4, 0.4)
	_star_colors[1] = Color.GOLD if score >= star_thresholds[1] else Color(0.4, 0.4, 0.4)
	_star_colors[2] = Color.GOLD if score >= star_thresholds[2] else Color(0.4, 0.4, 0.4)
	star1.queue_redraw()
	star2.queue_redraw()
	star3.queue_redraw()

func _draw_star(node: Node2D, idx: int) -> void:
	var color = _star_colors[idx]
	var pts = _star_points(Vector2.ZERO, 10.0, 4.5, 5)
	node.draw_colored_polygon(pts, color)
	var pts_inner = _star_points(Vector2.ZERO, 7.0, 3.5, 5)
	var highlight = lerp(color, Color.WHITE, 0.3)
	node.draw_colored_polygon(pts_inner, highlight)

static func _star_points(center: Vector2, outer_r: float, inner_r: float, points: int) -> PackedVector2Array:
	var result = PackedVector2Array()
	for i in points * 2:
		var angle = TAU * i / (points * 2) - PI / 2
		var r = outer_r if i % 2 == 0 else inner_r
		result.append(center + Vector2(cos(angle), sin(angle)) * r)
	return result

func _animate_score_pop() -> void:
	var tween = create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.1, 1.1), 0.08)
	tween.tween_property(score_label, "scale", Vector2.ONE, 0.08)
