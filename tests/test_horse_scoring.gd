extends GutTest

# Tests for Horse._score_lane() — the NPC lane evaluation function.
# We instantiate a real RaceTrack + Horse pair so the node references work
# exactly as in gameplay.

var track_node: RaceTrack
var horse_node: Node2D


func before_each() -> void:
	track_node = RaceTrack.new()
	add_child_autofree(track_node)
	await get_tree().process_frame

	horse_node = preload("res://Horse.gd").new() as Node2D
	track_node.add_child(horse_node)
	await get_tree().process_frame

	horse_node.horse_index = 0
	horse_node.lane_index = 3
	horse_node.is_npc = true


func test_boost_ahead_scores_positive() -> void:
	track_node.grid[2][3] = RaceTrack.Tile.BOOST
	var score := horse_node._score_lane(3, 1)
	assert_gt(score, 0.0, "Lane with BOOST ahead should score positive")


func test_slow_ahead_scores_negative() -> void:
	track_node.grid[2][3] = RaceTrack.Tile.SLOW
	var score := horse_node._score_lane(3, 1)
	assert_lt(score, GameConfig.LANE_STAY_BONUS, "Lane with SLOW ahead should score lower than staying bonus")


func test_current_lane_gets_stay_bonus() -> void:
	var score_current := horse_node._score_lane(horse_node.lane_index, 0)
	var score_adjacent := horse_node._score_lane(horse_node.lane_index + 1, 0)
	assert_gt(score_current, score_adjacent,
		"Current lane should be preferred when tiles are equal (stay bonus)")


func test_closer_tiles_outweigh_farther_tiles() -> void:
	var close_boost_score := 0.0
	var far_boost_score := 0.0

	track_node.grid[1][4] = RaceTrack.Tile.BOOST
	close_boost_score = horse_node._score_lane(4, 0)
	track_node.grid[1][4] = RaceTrack.Tile.EMPTY

	track_node.grid[4][4] = RaceTrack.Tile.BOOST
	far_boost_score = horse_node._score_lane(4, 0)
	track_node.grid[4][4] = RaceTrack.Tile.EMPTY

	assert_gt(close_boost_score, far_boost_score,
		"A BOOST 1 tile ahead should score higher than BOOST 4 tiles ahead")
