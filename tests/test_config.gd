extends GutTest

# Smoke tests: verify GameConfig constants have the expected values so that
# accidental edits to key game-balance numbers get caught immediately.

func test_karma_threshold_is_100() -> void:
	assert_eq(GameConfig.KARMA_THRESHOLD, 100.0)

func test_karma_penalties_are_positive() -> void:
	assert_gt(GameConfig.KARMA_BOOST_PENALTY, 0, "BOOST penalty must be positive")
	assert_gt(GameConfig.KARMA_SLOW_PENALTY, 0, "SLOW penalty must be positive")

func test_boost_penalty_greater_than_slow() -> void:
	assert_gt(GameConfig.KARMA_BOOST_PENALTY, GameConfig.KARMA_SLOW_PENALTY,
		"Placing a boost tile should cost more karma than a slow tile")

func test_speed_modifiers_in_valid_range() -> void:
	assert_gt(GameConfig.BOOST_MODIFIER, 1.0, "Boost must speed up horse")
	assert_lt(GameConfig.SLOW_MODIFIER, 1.0, "Slow must slow down horse")
	assert_gt(GameConfig.SLOW_MODIFIER, 0.0, "Slow modifier must be positive")

func test_lightning_speed_mod_is_very_slow() -> void:
	assert_lt(GameConfig.LIGHTNING_SPEED_MOD, GameConfig.SLOW_MODIFIER,
		"Lightning should be slower than a slow tile")

func test_grid_dimensions_are_positive() -> void:
	assert_gt(GameConfig.GRID_WIDTH, 0)
	assert_gt(GameConfig.GRID_HEIGHT, 0)
	assert_gt(GameConfig.CELL_SIZE, 0)

func test_finish_line_within_grid() -> void:
	assert_lt(GameConfig.FINISH_LINE_COL, GameConfig.GRID_WIDTH,
		"Finish line must be inside the grid")

func test_catchup_mult_is_reasonable() -> void:
	assert_gt(GameConfig.CATCHUP_MAX_MULT, 0.0)
	assert_lt(GameConfig.CATCHUP_MAX_MULT, 1.0, "Catch-up mult adds at most 100% speed bonus")

func test_npc_look_ahead_positive() -> void:
	assert_gt(GameConfig.NPC_LOOK_AHEAD, 0)

func test_slipstream_dist_positive() -> void:
	assert_gt(GameConfig.SLIPSTREAM_DIST, 0.0)
