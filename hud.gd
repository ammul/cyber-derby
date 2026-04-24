extends CanvasLayer

@onready var track: RaceTrack = $".."
@onready var progress_bar: ProgressBar = $UI/KarmaBar
@onready var karma_label: Label = $UI/KarmaLabel
@onready var win_overlay: ColorRect = $WinOverlay
@onready var winner_label: Label = $WinOverlay/WinnerText
@onready var countdown_label: Label = $CountdownLabel
@onready var position_label: Label = $PositionLabel
@onready var hint_label: Label = $HintLabel


func _ready() -> void:
	track.race_finished.connect(_on_race_finished)
	track.selection_done.connect(_on_selection_done)
	win_overlay.hide()
	countdown_label.show()
	countdown_label.text = "WÄHLE DEIN PFERD!"
	position_label.hide()
	hint_label.hide()


func _on_selection_done() -> void:
	_start_countdown()


func _start_countdown() -> void:
	countdown_label.show()
	countdown_label.text = "3"
	await get_tree().create_timer(GameConfig.COUNTDOWN_STEP).timeout
	countdown_label.text = "2"
	await get_tree().create_timer(GameConfig.COUNTDOWN_STEP).timeout
	countdown_label.text = "1"
	await get_tree().create_timer(GameConfig.COUNTDOWN_STEP).timeout
	countdown_label.text = "START!"
	if track:
		track.race_started = true
	hint_label.text = "Linke Hälfte: LANGSAM  |  Rechte Hälfte: BOOST"
	hint_label.modulate.a = 1.0
	hint_label.show()
	await get_tree().create_timer(GameConfig.COUNTDOWN_HIDE_DELAY).timeout
	countdown_label.hide()
	await get_tree().create_timer(3.0).timeout
	var tween := create_tween()
	tween.tween_property(hint_label, "modulate:a", 0.0, 1.0)
	await tween.finished
	hint_label.hide()


func _on_race_finished(horse_index: int, karma_score: float) -> void:
	win_overlay.show()
	if horse_index == track.selected_horse_index:
		winner_label.text = "SIEG! Dein Pferd hat gewonnen!"
		winner_label.modulate = GameConfig.COLOR_WIN
		if karma_score > GameConfig.KARMA_WIN_HIGH:
			winner_label.text += "\nDu hast zu viel manipuliert... Karma is a bitch!"
		elif karma_score < GameConfig.KARMA_WIN_LOW:
			winner_label.text += "\nSauberer Sieg! (Fast zu sauber...)"
	else:
		winner_label.text = "VERLOREN! Pferd " + str(horse_index + 1) + " war schneller."
		winner_label.modulate = GameConfig.COLOR_LOSE
	winner_label.text += "\nKarma-Stress: " + str(int(karma_score))


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _process(_delta: float) -> void:
	if not (track and progress_bar):
		return
	progress_bar.value = track.karma_points
	karma_label.text = "    K  A  R  M  A    "
	var fill_style: StyleBoxFlat = progress_bar.get_theme_stylebox("fill").duplicate()
	var ratio := track.karma_points / GameConfig.KARMA_THRESHOLD
	fill_style.bg_color = Color(ratio, 1.0 - ratio, 0.0).lerp(Color(1, 0, 0), ratio)
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	_update_position_label()


func _update_position_label() -> void:
	if not track.race_started or track.is_race_over or track.selected_horse_index < 0:
		position_label.hide()
		return
	var horses := get_tree().get_nodes_in_group(GameConfig.GROUP_HORSES)
	var my_x := 0.0
	for h in horses:
		if h.horse_index == track.selected_horse_index:
			my_x = h.position.x
			break
	var ahead := 0
	for h in horses:
		if h.horse_index != track.selected_horse_index and h.position.x > my_x:
			ahead += 1
	position_label.text = str(ahead + 1) + ". Platz"
	position_label.show()
