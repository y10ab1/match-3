extends Control

signal play_pressed
signal quit_pressed

func _ready() -> void:
	$VBoxContainer/PlayButton.pressed.connect(_on_play)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit)
	_animate_title()

func _on_play() -> void:
	AudioManager.play_button_sound()
	play_pressed.emit()

func _on_quit() -> void:
	get_tree().quit()

func _animate_title() -> void:
	var title = $VBoxContainer/TitleLabel
	var tween = create_tween().set_loops()
	tween.tween_property(title, "modulate", Color(1.0, 0.85, 0.4), 1.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(title, "modulate", Color(1.0, 0.5, 0.8), 1.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(title, "modulate", Color(0.5, 0.85, 1.0), 1.5).set_trans(Tween.TRANS_SINE)
