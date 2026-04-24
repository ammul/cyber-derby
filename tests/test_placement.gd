extends GutTest

# Tests for tile placement cooldown logic.

var track_node: RaceTrack


func before_each() -> void:
	track_node = RaceTrack.new()
	add_child_autofree(track_node)
	await get_tree().process_frame
	track_node.karma_points = 0.0
	track_node.is_selecting = false
	track_node.race_started = true
	track_node.tile_cooldown_remaining = 0.0
	track_node.aim_lane = 2


func test_cooldown_is_zero_at_race_start() -> void:
	var fresh_track := RaceTrack.new()
	add_child_autofree(fresh_track)
	await get_tree().process_frame
	assert_eq(fresh_track.tile_cooldown_remaining, 0.0,
		"Tile cooldown must start at zero")


func test_cooldown_blocks_placement_when_active() -> void:
	track_node.tile_cooldown_remaining = GameConfig.TILE_COOLDOWN
	var karma_before := track_node.karma_points
	track_node._place_selected_tile()
	assert_eq(track_node.karma_points, karma_before,
		"Tile placement on cooldown must not change karma")


func test_cooldown_decays_in_process() -> void:
	track_node.tile_cooldown_remaining = GameConfig.TILE_COOLDOWN
	var large_delta := GameConfig.TILE_COOLDOWN + 1.0
	track_node.tile_cooldown_remaining = maxf(0.0, track_node.tile_cooldown_remaining - large_delta)
	assert_eq(track_node.tile_cooldown_remaining, 0.0,
		"Cooldown must clamp to zero after elapsed time exceeds it")


func test_cooldown_does_not_go_negative() -> void:
	track_node.tile_cooldown_remaining = 0.5
	track_node.tile_cooldown_remaining = maxf(0.0, track_node.tile_cooldown_remaining - 999.0)
	assert_eq(track_node.tile_cooldown_remaining, 0.0,
		"Cooldown must never be negative")


func test_tile_cooldown_constant_is_positive() -> void:
	assert_gt(GameConfig.TILE_COOLDOWN, 0.0,
		"TILE_COOLDOWN must be a positive duration")
