extends CanvasLayer

@onready var score_label: Label = $TopBar/ScoreLabel
@onready var moves_label: Label = $TopBar/MovesLabel
@onready var objective_label: Label = $TopBar/ObjectiveLabel
@onready var score_bar: ProgressBar = $TopBar/ScoreBar
@onready var star1: Label = $TopBar/ScoreBar/Star1
@onready var star2: Label = $TopBar/ScoreBar/Star2
@onready var star3: Label = $TopBar/ScoreBar/Star3

var star_thresholds: Array[int] = []
var _score_objective_target: int = 0

func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.moves_changed.connect(_on_moves_changed)
	GameManager.objective_updated.connect(_on_objective_updated)

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
	star1.modulate = Color.GOLD if score >= star_thresholds[0] else Color(0.4, 0.4, 0.4)
	star2.modulate = Color.GOLD if score >= star_thresholds[1] else Color(0.4, 0.4, 0.4)
	star3.modulate = Color.GOLD if score >= star_thresholds[2] else Color(0.4, 0.4, 0.4)

func _animate_score_pop() -> void:
	var tween = create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.1, 1.1), 0.08)
	tween.tween_property(score_label, "scale", Vector2.ONE, 0.08)
