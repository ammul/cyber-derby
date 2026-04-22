extends Node2D

signal race_finished(winner_name, karma_score)

@export var finish_line_column: int = 100 # Wo das Rennen endet
@export var grid_width: int = 360
@export var grid_height: int = 8
@export var cell_size: int = 60
@export var placement_offset: float = 140.0 # Abstand vom rechten Rand in Pixeln

var is_aiming: bool = false
var aim_lane: int = 0
var aim_type = Tile.EMPTY

var karma_points: float = 0.0

enum Tile { EMPTY, BOOST, SLOW }
var grid = []
var is_race_over: bool = false

@export var start_line_x: float = 60 # Pixel-Position der Startlinie
var race_started: bool = false # Das "Go!"-Signal

func _ready():
	add_to_group("track_group")
	_generate_track()
# Wir starten das Rennen nicht sofort, sondern lassen das HUD den Countdown regeln

func _generate_track():
	grid.clear()
	for x in range(grid_width):
		var row = []
		for y in range(grid_height):
			row.append(Tile.EMPTY)
		grid.append(row)
		
	_place_random_tiles(Tile.BOOST, 3)
	_place_random_tiles(Tile.SLOW, 3)

func _place_random_tiles(type, count):
	var placed = 0
	while placed < count:
		var rx = randi_range(6, 12)
		var ry = randi_range(0, grid_height - 1)
		if grid[rx][ry] == Tile.EMPTY:
			grid[rx][ry] = type
			placed += 1

var selected_horse_index: int = -1 # Welches Pferd muss gewinnen?
var is_selecting: bool = true     # Sind wir gerade in der Auswahlphase?

# Signal für das HUD, wenn die Auswahl fertig ist
signal selection_done 



func _input(event):
	# Wenn wir noch in der Auswahlphase sind, ignorieren wir normales Malen
	if is_selecting:
		if event is InputEventMouseButton and event.pressed:
			_check_horse_selection(get_global_mouse_position())
		return
		
	if event is InputEventMouseButton and not is_race_over:
		var viewport_size = get_viewport_rect().size
		var mouse_pos = get_viewport().get_mouse_position()
		# PHASE 1: DRÜCKEN (Start der Vorschau)
		if event.pressed:
			is_aiming = true
			# Typ bestimmen: Links = SLOW, Rechts = BOOST
			if mouse_pos.x < viewport_size.x / 2.0:
				aim_type = Tile.SLOW
			else:
				aim_type = Tile.BOOST
			
			_update_aim_lane()

		# PHASE 3: LOSLASSEN (Platzieren)
		elif not event.pressed and is_aiming:
			_place_selected_tile()
			is_aiming = false
			queue_redraw()

	# PHASE 2: BEWEGEN / SWIPEN (Vorschau aktualisieren)
	if event is InputEventMouseMotion and is_aiming:
		_update_aim_lane()

func _update_aim_lane():
	var global_mouse = get_global_mouse_position()
	aim_lane = clamp(int(global_mouse.y / cell_size), 0, grid_height - 1)
	queue_redraw()

func _place_selected_tile():
	var viewport_size = get_viewport_rect().size
	var cam = get_viewport().get_camera_2d()
	if cam:
		var right_edge_global = cam.get_screen_center_position().x + (viewport_size.x / 2.0)
		var target_x_global = right_edge_global - placement_offset
		var gx = int(target_x_global / cell_size)
		
		if gx >= 0 and gx < grid_width:
			grid[gx][aim_lane] = aim_type
			# Karma erst beim Platzieren berechnen
			karma_points += 10 if aim_type == Tile.BOOST else 5


func _check_horse_selection(m_pos):
	for horse in get_tree().get_nodes_in_group("horses"):
		# Prüfe, ob die Maus in der Nähe eines Pferdes geklickt hat
		if horse.global_position.distance_to(m_pos) < 40:
			selected_horse_index = horse.horse_index
			is_selecting = false
			selection_done.emit() # Gib dem HUD Bescheid
			break

func _draw():
	# Raster-Linien zur Orientierung
	for y in range(grid_height + 1):
		draw_line(Vector2(0, y * cell_size), Vector2(grid_width * cell_size, y * cell_size), Color(1, 1, 1, 0.8))
	
	# Gezeichnete Tiles
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] == Tile.BOOST:
				draw_rect(Rect2(x * cell_size + 2, y * cell_size + 2, cell_size - 4, cell_size - 4), Color(0, 4, 2, 0.3))
			elif grid[x][y] == Tile.SLOW:
				draw_rect(Rect2(x * cell_size + 2, y * cell_size + 2, cell_size - 4, cell_size - 4), Color(4, 0, 2, 0.3))

	# Startlinie zeichnen (ein helles Blau oder Weiß)
	draw_rect(Rect2(start_line_x, 0, 5, grid_height * cell_size), Color(2,2,2,.5))

	# Zeichne die Ziellinie (leuchtendes Weiß/Gelb)
	var fx = finish_line_column * cell_size
	draw_rect(Rect2(fx, 0, 20, grid_height * cell_size), Color(0, 6, 0, .5)) # Glühendes Gelb

	# VORSCHAU ZEICHNEN
	if is_aiming:
		var viewport_size = get_viewport_rect().size
		var cam = get_viewport().get_camera_2d()
		if cam:
			var right_edge_global = cam.get_screen_center_position().x + (viewport_size.x / 2.0)
			var line_x = right_edge_global - placement_offset
			
			# Position des Vorschau-Rahmens
			# Wir runden auf das Grid ab, damit es bündig sitzt
			var rect_x = int(line_x / cell_size) * cell_size
			var rect_y = aim_lane * cell_size
			var preview_rect = Rect2(rect_x, rect_y, cell_size, cell_size)
			
			# Farbe wählen (Rot für Slow, Cyan für Boost)
			var preview_color = Color(4, 0, 2) if aim_type == Tile.SLOW else Color(0, 4, 2)
			
			# Nur den Rahmen zeichnen (Hohl)
			# draw_rect(rect, farbe, gefüllt?, breite)
			draw_rect(preview_rect, preview_color, false, 2.0)
			
			# Optional: Ein leichtes Flimmern im Rahmen für den Effekt
			draw_rect(preview_rect, Color(preview_color.r, preview_color.g, preview_color.b, 0.1), false)
			
# KARMA

var karma_threshold: float = 100.0

func _process(delta):
	# Karma baut sich ganz langsam von selbst ab (Heilung), 
	# aber Manipulationen erhöhen es viel schneller.
	karma_points = max(0, karma_points - delta * 2.0)
	
	if karma_points >= karma_threshold:
		trigger_karma_event()
		
	queue_redraw()

func trigger_karma_event():
	karma_points = 0 # Reset nach dem Event
	
	# Beispiel-Effekt: Erzeuge 5 zufällige Sumpf-Felder (SLOW) 
	# in der Nähe der aktuellen Kameraposition
	var cam_x = int(get_viewport().get_camera_2d().position.x / cell_size)
	
	for i in range(10):
		var rx = cam_x + 6 + randi_range(0, 20)
		var ry = randi_range(0, grid_height - 1)
		if rx < grid_width:
			grid[rx][ry] = Tile.SLOW
	
	var horses = get_tree().get_nodes_in_group("horses")
	
	for horse in horses:
		# Wir suchen genau DEIN ausgewähltes Pferd
		if horse.horse_index == selected_horse_index:
			if horse.has_method("get_struck_by_lightning"):
				horse.get_struck_by_lightning()
			break # Wir haben unser Ziel gefunden, Schleife beenden
	
	# Optional: Bildschirmwackeln (Screen Shake)
	_screen_shake()
	
	queue_redraw()

func _screen_shake():
	var cam = get_viewport().get_camera_2d()
	if cam:
		var tween = create_tween()
		tween.tween_property(cam, "offset", Vector2(8, 8), 0.15)
		tween.tween_property(cam, "offset", Vector2(-8, -8), 0.15)
		tween.tween_property(cam, "offset", Vector2(0, 0), 0.1)
