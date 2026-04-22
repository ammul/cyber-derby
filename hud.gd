extends CanvasLayer

# Wir nutzen @onready, um die Kinder-Nodes beim Start zu finden
@onready var track = $".."
@onready var progress_bar = $UI/KarmaBar
@onready var karma_label = $UI/KarmaLabel
@onready var win_overlay = $WinOverlay
@onready var winner_label = $WinOverlay/WinnerText
@onready var countdown_label = $CountdownLabel

func _ready():
	# Verbinde das Signal vom Track mit diesem HUD-Skript
	track.race_finished.connect(_on_race_finished)
	track.selection_done.connect(_on_selection_done)
	
	win_overlay.hide()

	countdown_label.show()
	countdown_label.text = "WÄHLE DEIN PFERD!"

func _on_selection_done():
	# Sobald ausgewählt wurde, startet der Countdown
	_start_countdown()

func _start_countdown():
	countdown_label.show()
	
	# 3
	countdown_label.text = "3"
	await get_tree().create_timer(1.0).timeout
	
	# 2
	countdown_label.text = "2"
	await get_tree().create_timer(1.0).timeout
	
	# 1
	countdown_label.text = "1"
	await get_tree().create_timer(1.0).timeout
	
	# GO!
	countdown_label.text = "START!"
	if track:
		track.race_started = true # Hier geben wir das Rennen frei!
	
	# Label nach kurzem Moment ausblenden
	await get_tree().create_timer(0.5).timeout
	countdown_label.hide()

func _on_race_finished(horse_index, karma_score):
	win_overlay.show()
	
	if horse_index == track.selected_horse_index:
		winner_label.text = "SIEG! Dein Pferd hat gewonnen!"
		winner_label.modulate = Color(0, 1, 0.5) # Erfolg-Grün
		# Je nach Karma geben wir einen frechen Kommentar (Roguelite-Stil)
		if karma_score > 66:
			winner_label.text += "\nDu hast zu viel manipuliert... Karma is a bitch!"
		elif karma_score < 33:
			winner_label.text += "\nSauberer Sieg! (Fast zu sauber...)"
	else:
		winner_label.text = "VERLOREN! Pferd " + str(horse_index + 1) + " war schneller."
		winner_label.modulate = Color(3, 0, 0) # Fehler-Rot
	
	winner_label.text += "\nKarma-Stress: " + str(int(karma_score))

# Wenn der Button gedrückt wird, laden wir die Szene neu
func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _process(_delta):
	if track and progress_bar:
		# Werte übertragen
		progress_bar.value = track.karma_points
		karma_label.text = "    K  A  R  M  A    "
		
		# Farbe dynamisch anpassen (von Grün nach Rot)
		var fill_style = progress_bar.get_theme_stylebox("fill").duplicate() 
		# .duplicate() ist wichtig, damit wir nicht alle ProgressBars im Spiel ändern
		
		var ratio = track.karma_points / 100.0
		fill_style.bg_color = Color(ratio, 1.0 - ratio, 0.0).lerp(Color(1, 0, 0), ratio)
		progress_bar.add_theme_stylebox_override("fill", fill_style)
