extends Node2D

@export var is_npc: bool = true 
var decision_timer: float = 0.0

@export var repulsion_radius: float = 40.0 
@export var repulsion_strength: float = 150.0 

@export var horse_index: int = 0
@onready var lane_index: int = horse_index
@export var body_color = Color(0.6, 0.4, 0.2) 
@export var head_color = Color(0.5, 0.3, 0.1) 
@export var base_speed: float = 110.0

@onready var track = $".."

var has_finished: bool = false
var speed_modifier: float = 1.0
var animation_time: float = 0.0

# Dynamik-Variablen
var noise_offset: float = randf() * 100.0 
var slipstream_bonus: float = 0.0          
var catch_up_mult: float = 1.0            
var target_mod_vis: float = 1.0           

var lightning_timer: float = 0.0
var is_shocked: bool = false


func _ready():
	add_to_group("horses")
	if track:
		position.x = track.start_line_x - 30
		position.y = lane_index * track.cell_size + (track.cell_size / 2)


func get_struck_by_lightning():
	is_shocked = true
	lightning_timer = 2.0 
	speed_modifier = 0.1 
	modulate = Color(10, 10, 10) 
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1) 


func _process(delta):
	if not track or track.is_race_over: return
	
	if not track.race_started:
		animation_time += delta * 5.0 
		_apply_visual_smoothing()
		queue_redraw()
		return 

	_check_tiles()

	var flavor_speed = sin(Time.get_ticks_msec() * 0.001 + noise_offset) * 15.0
	_calculate_dynamics()
	var total_speed = (base_speed + flavor_speed) * speed_modifier * catch_up_mult + slipstream_bonus
	total_speed = max(10.0, total_speed)
	
	position.x += total_speed * delta
	animation_time += delta * (total_speed * 0.05)

	_apply_visual_smoothing()
	_handle_npc_tactics(delta) # Pass delta here
	
	if is_shocked:
		lightning_timer -= delta
		if lightning_timer <= 0:
			is_shocked = false
			speed_modifier = 1.0 

	if position.x >= track.finish_line_column * track.cell_size and not has_finished:
		has_finished = true
		_celebrate_win()
		
	_handle_repulsion(delta)
	queue_redraw()


func _calculate_dynamics():
	var horses = get_tree().get_nodes_in_group("horses")
	if horses.is_empty(): return
	
	var lead_x = 0.0
	for h in horses: lead_x = max(lead_x, h.position.x)
	var dist_to_lead = lead_x - position.x
	catch_up_mult = 1.0 + clamp(dist_to_lead / 1500.0, 0.0, 0.3) 

	slipstream_bonus = 0.0
	target_mod_vis = 1.0 
	
	for other in horses:
		if other == self: continue
		var x_dist = other.position.x - self.position.x
		if other.lane_index == self.lane_index and x_dist > 0 and x_dist < 180:
			slipstream_bonus = (180.0 - x_dist) * 0.9
			target_mod_vis = 1.5 
			break 


func _handle_npc_tactics(delta):
	if not is_npc or speed_modifier < 0.9: return 
	
	decision_timer -= delta
	if decision_timer > 0: return # Only think every so often
	
	decision_timer = randf_range(0.2, 0.5) # Think more frequently than before
	
	var cell_x = int(position.x / track.cell_size)
	var look_ahead = 4 # Look ahead 4 tiles
	
	# 1. Collision avoidance (Highest Priority)
	var blocked = false
	for other in get_tree().get_nodes_in_group("horses"):
		if other == self: continue
		var x_dist = other.position.x - self.position.x
		if other.lane_index == self.lane_index and x_dist > 0 and x_dist < 60:
			blocked = true
			_try_switch_lane() # Try to get out of the way immediately
			return # Stop thinking for this cycle
			
	# 2. Evaluate Lanes
	var best_lane = lane_index
	var best_score = -9999.0
	
	# We'll check the current lane, the one above, and the one below
	var lanes_to_check = [lane_index]
	if lane_index > 0: lanes_to_check.append(lane_index - 1)
	if lane_index < track.grid_height - 1: lanes_to_check.append(lane_index + 1)
	
	for l in lanes_to_check:
		var score = 0.0
		
		# Base preference for staying in current lane to avoid jitter
		if l == lane_index: score += 1.0 
		
		# Check real tiles ahead
		for i in range(1, look_ahead + 1):
			var check_x = cell_x + i
			if check_x < track.grid_width:
				var tile = track.grid[check_x][l]
				# Closer tiles have a stronger impact
				var weight = float(look_ahead - i + 1) 
				if tile == track.Tile.BOOST:
					score += 5.0 * weight
				elif tile == track.Tile.SLOW:
					score -= 8.0 * weight # Strongly avoid slows
					
		# Check preview tiles (Lower priority than real tiles)
		if track.is_aiming and track.aim_lane == l:
			# Only care if the preview is roughly in front of us
			var preview_x = int((get_viewport().get_camera_2d().get_screen_center_position().x + (get_viewport_rect().size.x / 2.0) - track.placement_offset) / track.cell_size)
			if preview_x > cell_x and preview_x <= cell_x + look_ahead + 2:
				if track.aim_type == track.Tile.BOOST:
					score += 3.0
				elif track.aim_type == track.Tile.SLOW:
					score -= 4.0

		if score > best_score:
			best_score = score
			best_lane = l
			
	# 3. Apply Decision
	if best_lane != lane_index:
		_switch_to_lane(best_lane)


func _try_switch_lane():
	# Helper to switch to an adjacent valid lane
	var possible_lanes = []
	if lane_index > 0: possible_lanes.append(lane_index - 1)
	if lane_index < track.grid_height - 1: possible_lanes.append(lane_index + 1)
	
	if possible_lanes.size() > 0:
		_switch_to_lane(possible_lanes[randi() % possible_lanes.size()])

func _switch_to_lane(new_lane):
	if new_lane >= 0 and new_lane < track.grid_height:
		lane_index = new_lane

func _apply_visual_smoothing():
	if track:
		var target_y = float(lane_index * track.cell_size + (track.cell_size / 2.0))
		position.y = lerp(position.y, target_y, 0.1)
	
	modulate.r = lerp(modulate.r, 1.0, 0.1)
	modulate.g = lerp(modulate.g, 1.0, 0.1)
	modulate.b = lerp(modulate.b, float(target_mod_vis), 0.1) 

func _check_tiles():
	if is_shocked: return
	
	if track:
		var cell_x = int(position.x / track.cell_size)
		if cell_x >= 0 and cell_x < track.grid_width:
			var current_tile = track.grid[cell_x][lane_index]
			if current_tile == track.Tile.BOOST:
				speed_modifier = 1.5 
			elif current_tile == track.Tile.SLOW:
				speed_modifier = 0.5 
			else:
				speed_modifier = 1.0 

func _handle_repulsion(delta):
	for other in get_tree().get_nodes_in_group("horses"):
		if other == self: continue
		var diff = position - other.position
		var distance = diff.length()
		if distance < repulsion_radius:
			var push_force = diff.normalized() * (repulsion_radius - distance) * repulsion_strength
			position += push_force * delta
	

func _celebrate_win():
	track.is_race_over = true
	track.emit_signal("race_finished", horse_index, track.karma_points)


func _draw():
	var bob = sin(animation_time) * 3.0
	var leg_swing = sin(animation_time) * 6.0
	
	var draw_body_color = body_color
	var draw_head_color = head_color
	var draw_tail_color = head_color
	var draw_saddle_color = Color(1, 1, 1, 1)

	var draw_diff_color = Color(0,0, 0, 0)
	if speed_modifier > 1.2:
		draw_diff_color = Color(4, 4, 4, 0.5) 
	elif speed_modifier < 1:
		draw_diff_color = Color(4, 4, 0, 0.5) 

	draw_body_color = draw_body_color + draw_diff_color
	draw_head_color = draw_head_color + draw_diff_color
	draw_tail_color = draw_tail_color + draw_diff_color

	draw_line(Vector2(-10, -10 + bob), Vector2(-16, -4 + sin(animation_time*0.8)*7), draw_tail_color, 3.0)
	
	draw_line(Vector2(-7, -5 + bob), Vector2(-7 + leg_swing, 8), draw_body_color, 3.0)
	draw_line(Vector2(-4, -5 + bob), Vector2(-4 - leg_swing, 8), draw_body_color, 3.0)
	
	draw_rect(Rect2(-12, -15 + bob, 22, 12), draw_body_color)
	draw_rect(Rect2(-4, -15 + bob, 8, 4), draw_saddle_color) 
	
	var default_font = ThemeDB.get_fallback_font()
	var font_size = 10 
	var saddle_pos = Vector2(-5, -16 + bob)
	var saddle_size = Vector2(10, 10)
	draw_rect(Rect2(saddle_pos, saddle_size), draw_saddle_color)
	draw_string(default_font, saddle_pos + Vector2(0, 8), str(horse_index + 1), HORIZONTAL_ALIGNMENT_CENTER, saddle_size.x, font_size, Color(0, 0, 0))
	
	draw_line(Vector2(5, -5 + bob), Vector2(5 + leg_swing, 8), draw_body_color, 3.0)
	draw_line(Vector2(8, -5 + bob), Vector2(8 - leg_swing, 8), draw_body_color, 3.0)
	
	draw_line(Vector2(10, -10 + bob), Vector2(15, -20 + bob), draw_body_color, 5.0) 
	draw_rect(Rect2(13, -24 + bob, 10, 7), draw_head_color) 
	draw_rect(Rect2(14, -26 + bob, 2, 3), draw_head_color) 

	if track and track.selected_horse_index == horse_index:
		var wobble = sin(animation_time * 1.0) * 5.0
		var top_y = -30.0 + wobble 
		var p1 = Vector2(-8, top_y)          
		var p2 = Vector2(8, top_y)           
		var p3 = Vector2(0, top_y + 10.0)     
		var triangle_points = PackedVector2Array([p1, p2, p3])
		draw_colored_polygon(triangle_points, Color(0, 4, 0))
		draw_polyline(PackedVector2Array([p1, p2, p3, p1]), Color(1, 1, 1), 2.0)

	if is_shocked:
		if randf() > 0.8:
			var zap_color = Color(3, 3, 0, 0.6) 
			var points = PackedVector2Array()
			var current_y = -500.0 
			var segments = 6
			points.append(Vector2(randf_range(-50, 50), current_y))
			for i in range(1, segments):
				var progress = float(i) / segments
				var x_offset = randf_range(-40, 40)
				points.append(Vector2(x_offset, current_y * (1.0 - progress)))
			points.append(Vector2(0, 0)) 
			draw_polyline(points, zap_color, 3.0) 
			draw_polyline(points, Color(2, 2, 10), 1.0) 

	if slipstream_bonus > 20.0 and not has_finished:
		var line_color = Color(1, 1, 5, 0.5) 
		var line_width = 1.5
		for i in range(3):
			var time_off = animation_time * 15.0 + (i * 2.1)
			var start_x = -15.0 - (fmod(time_off, 40.0))
			var line_y = -10.0 + (i * 8.0) + sin(time_off) * 2.0
			var line_len = 25.0 + (slipstream_bonus * 0.2)
			var p1 = Vector2(start_x, line_y)
			var p2 = Vector2(start_x - line_len, line_y)
			draw_polyline(PackedVector2Array([p1, p2]), line_color, line_width)
			draw_polyline(PackedVector2Array([p1, p2]), Color(2, 2, 10, 0.3), 0.5)
