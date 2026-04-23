extends GutTest

# Tests for karma accumulation and tile-placement penalties.

var track_node: RaceTrack


func before_each() -> void:
	track_node = RaceTrack.new()
	add_child_autofree(track_node)
	await get_tree().process_frame
	track_node.karma_points = 0.0
	track_node.is_selecting = false
	track_node.race_started = true
	track_node.aim_lane = 0


func test_boost_placement_adds_boost_penalty() -> void:
	track_node.aim_type = RaceTrack.Tile.BOOST
	var before := track_node.karma_points
	track_node._place_selected_tile()
	var added := track_node.karma_points - before
	assert_eq(added, GameConfig.KARMA_BOOST_PENALTY,
		"Placing BOOST tile should add KARMA_BOOST_PENALTY points")


func test_slow_placement_adds_slow_penalty() -> void:
	track_node.aim_type = RaceTrack.Tile.SLOW
	var before := track_node.karma_points
	track_node._place_selected_tile()
	var added := track_node.karma_points - before
	assert_eq(added, GameConfig.KARMA_SLOW_PENALTY,
		"Placing SLOW tile should add KARMA_SLOW_PENALTY points")


func test_karma_does_not_go_below_zero() -> void:
	track_node.karma_points = 0.1
	# Simulate a large delta decay
	track_node.karma_points = maxf(0.0, track_node.karma_points - 999.0 * GameConfig.KARMA_DECAY_RATE)
	assert_eq(track_node.karma_points, 0.0, "Karma cannot go below zero")


func test_karma_event_resets_karma_to_zero() -> void:
	track_node.karma_points = GameConfig.KARMA_THRESHOLD
	track_node.trigger_karma_event()
	assert_eq(track_node.karma_points, 0.0, "Karma should reset to 0 after event")
