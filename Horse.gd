extends Node2D

signal horse_finished(horse_index: int, karma_score: float)

@export var is_npc: bool = true
@export var horse_index: int = 0
@export var body_color: Color = Color(0.6, 0.4, 0.2)
@export var head_color: Color = Color(0.5, 0.3, 0.1)
@export var base_speed: float = GameConfig.BASE_SPEED
@export var repulsion_radius: float = GameConfig.REPULSION_RADIUS
@export var repulsion_strength: float = GameConfig.REPULSION_STRENGTH

@onready var lane_index: int = horse_index
@onready var track: RaceTrack = $".."

var has_finished: bool = false
var speed_modifier: float = 1.0
var animation_time: float = 0.0

var noise_offset: float = randf() * 100.0
var slipstream_bonus: float = 0.0
var catch_up_mult: float = 1.0
var target_mod_vis: float = 1.0

var lightning_timer: float = 0.0
var is_shocked: bool = false
var is_male: bool = false

var _horses_cache: Array = []
var _decision_timer: float = 0.0


func _ready() -> void:
	is_male = randf() > 0.5
	add_to_group(GameConfig.GROUP_HORSES)
	if track:
		position.x = GameConfig.START_LINE_X - 30
		position.y = lane_index * GameConfig.CELL_SIZE + (GameConfig.CELL_SIZE / 2.0)
	call_deferred("_init_horses_cache")


func _init_horses_cache() -> void:
	_horses_cache = get_tree().get_nodes_in_group(GameConfig.GROUP_HORSES)


func get_struck_by_lightning() -> void:
	is_shocked = true
	lightning_timer = GameConfig.LIGHTNING_DURATION
	speed_modifier = GameConfig.LIGHTNING_SPEED_MOD
	modulate = Color(10, 10, 10)
	await get_tree().create_timer(GameConfig.LIGHTNING_FLASH_DUR).timeout
	modulate = Color(1, 1, 1)


func _process(delta: float) -> void:
	if not track or track.is_race_over:
		return
	if not track.race_started:
		animation_time += delta * GameConfig.PRE_RACE_ANIM_SPEED
		_apply_visual_smoothing()
		queue_redraw()
		return

	_check_tiles()
	_update_movement(delta)
	_apply_visual_smoothing()
	_handle_lightning_timer(delta)
	_check_finish_line()
	if is_npc:
		_handle_npc_tactics(delta)
	_handle_repulsion(delta)
	queue_redraw()


func _update_movement(delta: float) -> void:
	var flavor_speed := sin(Time.get_ticks_msec() * GameConfig.FLAVOR_FREQUENCY + noise_offset) * GameConfig.FLAVOR_AMPLITUDE
	_calculate_dynamics()
	var total_speed := (base_speed + flavor_speed) * speed_modifier * catch_up_mult + slipstream_bonus
	total_speed = maxf(GameConfig.MIN_SPEED, total_speed)
	position.x += total_speed * delta
	animation_time += delta * (total_speed * GameConfig.ANIM_SPEED_SCALE)


func _handle_lightning_timer(delta: float) -> void:
	if not is_shocked:
		return
	lightning_timer -= delta
	if lightning_timer <= 0.0:
		is_shocked = false
		speed_modifier = 1.0


func _check_finish_line() -> void:
	if has_finished:
		return
	if position.x >= GameConfig.FINISH_LINE_COL * GameConfig.CELL_SIZE:
		has_finished = true
		horse_finished.emit(horse_index, track.karma_points)


func _calculate_dynamics() -> void:
	if _horses_cache.is_empty():
		return
	var lead_x := 0.0
	for h: Node2D in _horses_cache:
		lead_x = maxf(lead_x, h.position.x)
	var dist_to_lead := lead_x - position.x
	catch_up_mult = 1.0 + clamp(dist_to_lead / GameConfig.CATCHUP_DIST_THRESHOLD, 0.0, GameConfig.CATCHUP_MAX_MULT)

	slipstream_bonus = 0.0
	target_mod_vis = 1.0
	for other in _horses_cache:
		if other == self:
			continue
		var x_dist: float = other.position.x - position.x
		if other.lane_index == lane_index and x_dist > 0.0 and x_dist < GameConfig.SLIPSTREAM_DIST:
			slipstream_bonus = (GameConfig.SLIPSTREAM_DIST - x_dist) * GameConfig.SLIPSTREAM_BONUS_MULT
			target_mod_vis = GameConfig.SLIPSTREAM_VIS_BOOST
			break


func _handle_npc_tactics(delta: float) -> void:
	if speed_modifier < GameConfig.NPC_SPEED_MOD_MIN:
		return
	_decision_timer -= delta
	if _decision_timer > 0.0:
		return
	_decision_timer = randf_range(GameConfig.NPC_DECISION_MIN, GameConfig.NPC_DECISION_MAX)

	var cell_x := int(position.x / GameConfig.CELL_SIZE)

	# Collision avoidance — highest priority
	for other in _horses_cache:
		if other == self:
			continue
		var x_dist: float = other.position.x - position.x
		if other.lane_index == lane_index and x_dist > 0.0 and x_dist < GameConfig.NPC_COLLISION_DIST:
			_try_switch_lane()
			return

	# Lane scoring
	var best_lane := lane_index
	var best_score := -9999.0
	var lanes_to_check := [lane_index]
	if lane_index > 0:
		lanes_to_check.append(lane_index - 1)
	if lane_index < GameConfig.GRID_HEIGHT - 1:
		lanes_to_check.append(lane_index + 1)

	for l: int in lanes_to_check:
		var score := _score_lane(l, cell_x)
		if score > best_score:
			best_score = score
			best_lane = l

	if best_lane != lane_index:
		_switch_to_lane(best_lane)


func _score_lane(lane: int, cell_x: int) -> float:
	var score := GameConfig.LANE_STAY_BONUS if lane == lane_index else 0.0

	for i in range(1, GameConfig.NPC_LOOK_AHEAD + 1):
		var check_x := cell_x + i
		if check_x < GameConfig.GRID_WIDTH:
			var tile = track.grid[check_x][lane]
			var weight := float(GameConfig.NPC_LOOK_AHEAD - i + 1)
			if tile == RaceTrack.Tile.BOOST:
				score += GameConfig.BOOST_LANE_WEIGHT * weight
			elif tile == RaceTrack.Tile.SLOW:
				score -= GameConfig.SLOW_LANE_WEIGHT * weight

	if track.is_aiming and track.aim_lane == lane:
		var cam := get_viewport().get_camera_2d()
		if cam:
			var preview_x := int((cam.get_screen_center_position().x + get_viewport_rect().size.x / 2.0 - GameConfig.PLACEMENT_OFFSET) / GameConfig.CELL_SIZE)
			if preview_x > cell_x and preview_x <= cell_x + GameConfig.NPC_LOOK_AHEAD + 2:
				if track.aim_type == RaceTrack.Tile.BOOST:
					score += GameConfig.PREVIEW_BOOST_WEIGHT
				elif track.aim_type == RaceTrack.Tile.SLOW:
					score -= GameConfig.PREVIEW_SLOW_WEIGHT

	return score


func _try_switch_lane() -> void:
	var options: Array = []
	if lane_index > 0:
		options.append(lane_index - 1)
	if lane_index < GameConfig.GRID_HEIGHT - 1:
		options.append(lane_index + 1)
	if options.size() > 0:
		_switch_to_lane(options[randi() % options.size()])


func _switch_to_lane(new_lane: int) -> void:
	if new_lane >= 0 and new_lane < GameConfig.GRID_HEIGHT:
		lane_index = new_lane


func _apply_visual_smoothing() -> void:
	if track:
		var target_y := lane_index * GameConfig.CELL_SIZE + (GameConfig.CELL_SIZE / 2.0)
		position.y = lerp(position.y, target_y, GameConfig.VISUAL_LERP_SPEED)
	modulate = modulate.lerp(Color(1.0, 1.0, target_mod_vis, 1.0), GameConfig.VISUAL_LERP_SPEED)


func _check_tiles() -> void:
	if is_shocked or not track:
		return
	var cell_x := int(position.x / GameConfig.CELL_SIZE)
	if cell_x >= 0 and cell_x < GameConfig.GRID_WIDTH:
		var tile = track.grid[cell_x][lane_index]
		if tile == RaceTrack.Tile.BOOST:
			speed_modifier = GameConfig.BOOST_MODIFIER
		elif tile == RaceTrack.Tile.SLOW:
			speed_modifier = GameConfig.SLOW_MODIFIER
		else:
			speed_modifier = 1.0


func _handle_repulsion(delta: float) -> void:
	for other: Node2D in _horses_cache:
		if other == self:
			continue
		var diff := position - other.position
		var distance := diff.length()
		if distance < repulsion_radius and distance > 0.0:
			position += diff.normalized() * (repulsion_radius - distance) * repulsion_strength * delta


func _draw() -> void:
	var bob := sin(animation_time) * GameConfig.BOB_AMPLITUDE
	var leg_swing := sin(animation_time) * GameConfig.LEG_AMPLITUDE
	_draw_body(bob, leg_swing)
	_draw_selection_indicator()
	_draw_lightning_effect()
	_draw_slipstream()


func _draw_body(bob: float, leg_swing: float) -> void:
	var tint := Color(0, 0, 0, 0)
	if speed_modifier > 1.2:
		tint = GameConfig.COLOR_BOOST_TINT
	elif speed_modifier < 1.0:
		tint = GameConfig.COLOR_SLOW_TINT

	var draw_body_color := body_color + tint
	var draw_head_color := head_color + tint
	var draw_tail_color := head_color + tint

	draw_line(Vector2(-10, -10 + bob), Vector2(-16, -4 + sin(animation_time * GameConfig.TAIL_FREQ) * GameConfig.TAIL_AMPLITUDE), draw_tail_color, 3.0)

	draw_line(Vector2(-7, -5 + bob), Vector2(-7 + leg_swing, 8), draw_body_color, 3.0)
	draw_line(Vector2(-4, -5 + bob), Vector2(-4 - leg_swing, 8), draw_body_color, 3.0)

	draw_rect(Rect2(-12, -15 + bob, 22, 12), draw_body_color)

	if is_male:
		_draw_male_anatomy(bob, draw_body_color)

	draw_rect(Rect2(-4, -15 + bob, 8, 4), Color(1, 1, 1, 1))

	draw_line(Vector2(5, -5 + bob), Vector2(5 + leg_swing, 8), draw_body_color, 3.0)
	draw_line(Vector2(8, -5 + bob), Vector2(8 - leg_swing, 8), draw_body_color, 3.0)

	draw_line(Vector2(10, -10 + bob), Vector2(15, -20 + bob), draw_body_color, 5.0)
	draw_rect(Rect2(13, -24 + bob, 10, 7), draw_head_color)
	draw_rect(Rect2(14, -26 + bob, 2, 3), draw_head_color)

	_draw_rider(bob, draw_body_color)


func _draw_rider(bob: float, jersey_color: Color) -> void:
	var skin := Color(0.95, 0.78, 0.62)
	var helmet_color := Color(0.15, 0.15, 0.75)

	# Lower legs hanging alongside the horse's barrel
	draw_line(Vector2(-3, -15 + bob), Vector2(-9, -8 + bob), jersey_color, 2.5)
	draw_line(Vector2(3, -15 + bob), Vector2(9, -8 + bob), jersey_color, 2.5)

	# Torso (jersey in horse's colours)
	draw_rect(Rect2(-3, -24 + bob, 6, 9), jersey_color)

	# Race-number bib on torso
	var default_font := ThemeDB.get_fallback_font()
	draw_string(default_font, Vector2(-3, -20 + bob), str(horse_index + 1), HORIZONTAL_ALIGNMENT_CENTER, 6, GameConfig.SADDLE_FONT_SIZE, Color(1, 1, 1))

	# Head (skin)
	draw_rect(Rect2(-3, -29 + bob, 6, 5), skin)

	# Helmet body + brim
	draw_rect(Rect2(-4, -34 + bob, 8, 6), helmet_color)
	draw_rect(Rect2(-5, -29 + bob, 10, 2), helmet_color)

	# Forward arm holding reins
	draw_line(Vector2(3, -21 + bob), Vector2(13, -18 + bob), skin, 2.0)


func _draw_male_anatomy(bob: float, coat_color: Color) -> void:
	var phallus_color := coat_color.darkened(0.25)
	# Sheath hanging from belly between rear legs
	draw_rect(Rect2(-9, -2 + bob, 5, 6), phallus_color)
	draw_circle(Vector2(-6, 5 + bob), 2.5, phallus_color)
	# Testes
	draw_circle(Vector2(-4, 7 + bob), 2.5, phallus_color)
	draw_circle(Vector2(-9, 7 + bob), 2.5, phallus_color)


func _draw_selection_indicator() -> void:
	if not (track and track.selected_horse_index == horse_index):
		return
	var wobble := sin(animation_time * GameConfig.SELECTION_WOBBLE_FREQ) * GameConfig.SELECTION_WOBBLE_AMP
	var top_y := GameConfig.SELECTION_TOP_Y + wobble
	var p1 := Vector2(-8, top_y)
	var p2 := Vector2(8, top_y)
	var p3 := Vector2(0, top_y + GameConfig.SELECTION_TRI_H)
	draw_colored_polygon(PackedVector2Array([p1, p2, p3]), GameConfig.COLOR_SELECTION)
	draw_polyline(PackedVector2Array([p1, p2, p3, p1]), Color(1, 1, 1), 2.0)


func _draw_lightning_effect() -> void:
	if not is_shocked or randf() <= GameConfig.LIGHTNING_THRESHOLD:
		return
	var points := PackedVector2Array()
	var current_y := GameConfig.LIGHTNING_START_Y
	points.append(Vector2(randf_range(-50, 50), current_y))
	for i in range(1, GameConfig.LIGHTNING_SEGMENTS):
		var progress := float(i) / GameConfig.LIGHTNING_SEGMENTS
		points.append(Vector2(randf_range(-40, 40), current_y * (1.0 - progress)))
	points.append(Vector2(0, 0))
	draw_polyline(points, GameConfig.COLOR_LIGHTNING_ZAP, 3.0)
	draw_polyline(points, GameConfig.COLOR_LIGHTNING_CORE, 1.0)


func _draw_slipstream() -> void:
	if slipstream_bonus <= GameConfig.SLIPSTREAM_DRAW_THRESH or has_finished:
		return
	for i in range(GameConfig.SLIPSTREAM_LINE_COUNT):
		var time_off := animation_time * GameConfig.SLIPSTREAM_ANIM_SPEED + (i * GameConfig.SLIPSTREAM_ANIM_PHASE)
		var start_x := -15.0 - fmod(time_off, GameConfig.SLIPSTREAM_SCROLL_MOD)
		var line_y := -10.0 + (i * 8.0) + sin(time_off) * 2.0
		var line_len := GameConfig.SLIPSTREAM_LEN_BASE + (slipstream_bonus * GameConfig.SLIPSTREAM_LEN_BONUS)
		var p1 := Vector2(start_x, line_y)
		var p2 := Vector2(start_x - line_len, line_y)
		draw_polyline(PackedVector2Array([p1, p2]), GameConfig.COLOR_SLIPSTREAM, GameConfig.SLIPSTREAM_LINE_WIDTH)
		draw_polyline(PackedVector2Array([p1, p2]), GameConfig.COLOR_SLIPSTREAM_CORE, 0.5)
