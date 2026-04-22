class_name RaceTrack
extends Node2D

signal race_finished(winner_index: int, karma_score: float)
signal selection_done

enum Tile { EMPTY, BOOST, SLOW }

var grid: Array = []
var is_race_over: bool = false
var race_started: bool = false
var karma_points: float = 0.0

var is_aiming: bool = false
var aim_lane: int = 0
var aim_type: Tile = Tile.EMPTY

var selected_horse_index: int = -1
var is_selecting: bool = true


func _ready() -> void:
	add_to_group(GameConfig.GROUP_TRACK)
	_generate_track()
	for horse in get_tree().get_nodes_in_group(GameConfig.GROUP_HORSES):
		horse.horse_finished.connect(_on_horse_finished)


func _generate_track() -> void:
	grid.clear()
	for x in range(GameConfig.GRID_WIDTH):
		var col: Array = []
		for y in range(GameConfig.GRID_HEIGHT):
			col.append(Tile.EMPTY)
		grid.append(col)
	_place_random_tiles(Tile.BOOST, GameConfig.INITIAL_BOOST_TILES)
	_place_random_tiles(Tile.SLOW, GameConfig.INITIAL_SLOW_TILES)


func _place_random_tiles(type: Tile, count: int) -> void:
	var placed := 0
	while placed < count:
		var rx := randi_range(GameConfig.TILE_SPAWN_X_MIN, GameConfig.TILE_SPAWN_X_MAX)
		var ry := randi_range(0, GameConfig.GRID_HEIGHT - 1)
		if grid[rx][ry] == Tile.EMPTY:
			grid[rx][ry] = type
			placed += 1


func _input(event: InputEvent) -> void:
	if is_selecting:
		_handle_selection_click(event)
		return
	if not is_race_over:
		_handle_aiming(event)


func _handle_selection_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_check_horse_selection(get_global_mouse_position())


func _handle_aiming(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			is_aiming = true
			var mouse_x := get_viewport().get_mouse_position().x
			aim_type = Tile.SLOW if mouse_x < get_viewport_rect().size.x / 2.0 else Tile.BOOST
			_update_aim_lane()
		elif is_aiming:
			_place_selected_tile()
			is_aiming = false
			queue_redraw()
	if event is InputEventMouseMotion and is_aiming:
		_update_aim_lane()


func _update_aim_lane() -> void:
	aim_lane = clamp(int(get_global_mouse_position().y / GameConfig.CELL_SIZE), 0, GameConfig.GRID_HEIGHT - 1)
	queue_redraw()


func _get_placement_x_global() -> float:
	var cam := get_viewport().get_camera_2d()
	if not cam:
		return -1.0
	var right_edge := cam.get_screen_center_position().x + (get_viewport_rect().size.x / 2.0)
	return right_edge - GameConfig.PLACEMENT_OFFSET


func _place_selected_tile() -> void:
	var place_x := _get_placement_x_global()
	if place_x < 0.0:
		return
	var gx := int(place_x / GameConfig.CELL_SIZE)
	if gx >= 0 and gx < GameConfig.GRID_WIDTH:
		grid[gx][aim_lane] = aim_type
		karma_points += GameConfig.KARMA_BOOST_PENALTY if aim_type == Tile.BOOST else GameConfig.KARMA_SLOW_PENALTY


func _check_horse_selection(m_pos: Vector2) -> void:
	for horse in get_tree().get_nodes_in_group(GameConfig.GROUP_HORSES):
		if horse.global_position.distance_to(m_pos) < GameConfig.HORSE_SELECT_RADIUS:
			selected_horse_index = horse.horse_index
			is_selecting = false
			selection_done.emit()
			break


func _process(delta: float) -> void:
	karma_points = maxf(0.0, karma_points - delta * GameConfig.KARMA_DECAY_RATE)
	if karma_points >= GameConfig.KARMA_THRESHOLD:
		trigger_karma_event()
	queue_redraw()


func trigger_karma_event() -> void:
	karma_points = 0.0
	_spawn_punishment_tiles()
	for horse in get_tree().get_nodes_in_group(GameConfig.GROUP_HORSES):
		if horse.horse_index == selected_horse_index:
			if horse.has_method("get_struck_by_lightning"):
				horse.get_struck_by_lightning()
			break
	_screen_shake()
	queue_redraw()


func _spawn_punishment_tiles() -> void:
	var cam_x := int(get_viewport().get_camera_2d().position.x / GameConfig.CELL_SIZE)
	for i in range(GameConfig.KARMA_EVENT_SLOW_COUNT):
		var rx := cam_x + 6 + randi_range(0, 20)
		var ry := randi_range(0, GameConfig.GRID_HEIGHT - 1)
		if rx < GameConfig.GRID_WIDTH:
			grid[rx][ry] = Tile.SLOW


func _screen_shake() -> void:
	var cam := get_viewport().get_camera_2d()
	if not cam:
		return
	var tween := create_tween()
	tween.tween_property(cam, "offset", Vector2(GameConfig.SHAKE_OFFSET, GameConfig.SHAKE_OFFSET), GameConfig.SHAKE_DURATION)
	tween.tween_property(cam, "offset", Vector2(-GameConfig.SHAKE_OFFSET, -GameConfig.SHAKE_OFFSET), GameConfig.SHAKE_DURATION)
	tween.tween_property(cam, "offset", Vector2.ZERO, GameConfig.SHAKE_RETURN)


func _on_horse_finished(horse_index: int, karma_score: float) -> void:
	if is_race_over:
		return
	is_race_over = true
	race_finished.emit(horse_index, karma_score)


func _draw() -> void:
	for y in range(GameConfig.GRID_HEIGHT + 1):
		draw_line(
			Vector2(0, y * GameConfig.CELL_SIZE),
			Vector2(GameConfig.GRID_WIDTH * GameConfig.CELL_SIZE, y * GameConfig.CELL_SIZE),
			Color(1, 1, 1, 0.8)
		)

	for x in range(GameConfig.GRID_WIDTH):
		for y in range(GameConfig.GRID_HEIGHT):
			var tile: Tile = grid[x][y]
			if tile == Tile.BOOST:
				draw_rect(Rect2(x * GameConfig.CELL_SIZE + 2, y * GameConfig.CELL_SIZE + 2, GameConfig.CELL_SIZE - 4, GameConfig.CELL_SIZE - 4), GameConfig.COLOR_BOOST_TILE)
			elif tile == Tile.SLOW:
				draw_rect(Rect2(x * GameConfig.CELL_SIZE + 2, y * GameConfig.CELL_SIZE + 2, GameConfig.CELL_SIZE - 4, GameConfig.CELL_SIZE - 4), GameConfig.COLOR_SLOW_TILE)

	draw_rect(Rect2(GameConfig.START_LINE_X, 0, 5, GameConfig.GRID_HEIGHT * GameConfig.CELL_SIZE), GameConfig.COLOR_START_LINE)

	var fx := GameConfig.FINISH_LINE_COL * GameConfig.CELL_SIZE
	draw_rect(Rect2(fx, 0, 20, GameConfig.GRID_HEIGHT * GameConfig.CELL_SIZE), GameConfig.COLOR_FINISH_LINE)

	if is_aiming:
		var line_x := _get_placement_x_global()
		if line_x < 0.0:
			return
		var rect_x := int(line_x / GameConfig.CELL_SIZE) * GameConfig.CELL_SIZE
		var rect_y := aim_lane * GameConfig.CELL_SIZE
		var preview_rect := Rect2(rect_x, rect_y, GameConfig.CELL_SIZE, GameConfig.CELL_SIZE)
		var preview_color := GameConfig.COLOR_SLOW_TILE if aim_type == Tile.SLOW else GameConfig.COLOR_BOOST_TILE
		draw_rect(preview_rect, preview_color, false, 2.0)
		draw_rect(preview_rect, Color(preview_color.r, preview_color.g, preview_color.b, 0.1), false)
