class_name GameConfig

# Group names
const GROUP_HORSES := &"horses"
const GROUP_TRACK  := &"track_group"

# Track geometry
const GRID_WIDTH       := 360
const GRID_HEIGHT      := 8
const CELL_SIZE        := 60
const FINISH_LINE_COL  := 100
const START_LINE_X     := 60.0
const PLACEMENT_OFFSET := 140.0

# Tile seeding
const INITIAL_BOOST_TILES := 3
const INITIAL_SLOW_TILES  := 3
const TILE_SPAWN_X_MIN    := 6
const TILE_SPAWN_X_MAX    := 12

# Karma
const KARMA_THRESHOLD        := 100.0
const KARMA_DECAY_RATE       := 2.0
const KARMA_BOOST_PENALTY    := 10
const KARMA_SLOW_PENALTY     := 5
const KARMA_EVENT_SLOW_COUNT := 10
const KARMA_WIN_HIGH         := 66.0
const KARMA_WIN_LOW          := 33.0

# Countdown
const COUNTDOWN_STEP       := 1.0
const COUNTDOWN_HIDE_DELAY := 0.5

# Horse movement
const BASE_SPEED          := 110.0
const MIN_SPEED           := 10.0
const FLAVOR_AMPLITUDE    := 15.0
const FLAVOR_FREQUENCY    := 0.001
const ANIM_SPEED_SCALE    := 0.05
const PRE_RACE_ANIM_SPEED := 5.0
const BOOST_MODIFIER      := 1.5
const SLOW_MODIFIER       := 0.5
const LIGHTNING_DURATION  := 2.0
const LIGHTNING_SPEED_MOD := 0.1
const LIGHTNING_FLASH_DUR := 0.1
const VISUAL_LERP_SPEED   := 0.1

# Dynamics
const CATCHUP_DIST_THRESHOLD := 1500.0
const CATCHUP_MAX_MULT       := 0.3
const SLIPSTREAM_DIST        := 180.0
const SLIPSTREAM_BONUS_MULT  := 0.9
const SLIPSTREAM_VIS_BOOST   := 1.5
const SLIPSTREAM_DRAW_THRESH := 20.0

# NPC AI
const NPC_DECISION_MIN     := 0.2
const NPC_DECISION_MAX     := 0.5
const NPC_LOOK_AHEAD       := 4
const NPC_COLLISION_DIST   := 60.0
const NPC_SPEED_MOD_MIN    := 0.9
const BOOST_LANE_WEIGHT    := 5.0
const SLOW_LANE_WEIGHT     := 8.0
const PREVIEW_BOOST_WEIGHT := 3.0
const PREVIEW_SLOW_WEIGHT  := 4.0
const LANE_STAY_BONUS      := 1.0

# Physics / repulsion
const REPULSION_RADIUS   := 40.0
const REPULSION_STRENGTH := 150.0

# Camera (follow_speed is in units/second; higher = snappier)
const CAMERA_SMOOTHING   := 5.0
const CAMERA_LEAD_OFFSET := 200.0

# Selection
const HORSE_SELECT_RADIUS := 40.0

# Screen shake
const SHAKE_OFFSET   := 8.0
const SHAKE_DURATION := 0.15
const SHAKE_RETURN   := 0.1

# Rendering — HDR values are intentional; > 1.0 drives bloom in HDR 2D mode
const COLOR_BOOST_TILE     := Color(0, 4, 2, 0.3)
const COLOR_SLOW_TILE      := Color(4, 0, 2, 0.3)
const COLOR_FINISH_LINE    := Color(0, 6, 0, 0.5)
const COLOR_START_LINE     := Color(2, 2, 2, 0.5)
const COLOR_SELECTION      := Color(0, 4, 0)
const COLOR_LIGHTNING_ZAP  := Color(3, 3, 0, 0.6)
const COLOR_LIGHTNING_CORE := Color(2, 2, 10)
const COLOR_SLIPSTREAM     := Color(1, 1, 5, 0.5)
const COLOR_SLIPSTREAM_CORE:= Color(2, 2, 10, 0.3)
const COLOR_BOOST_TINT     := Color(4, 4, 4, 0.5)
const COLOR_SLOW_TINT      := Color(4, 4, 0, 0.5)
const COLOR_WIN            := Color(0, 1, 0.5)
const COLOR_LOSE           := Color(3, 0, 0)

# Horse rendering
const SADDLE_FONT_SIZE      := 10
const BOB_AMPLITUDE         := 3.0
const LEG_AMPLITUDE         := 6.0
const TAIL_FREQ             := 0.8
const TAIL_AMPLITUDE        := 7.0
const SELECTION_WOBBLE_FREQ := 1.0
const SELECTION_WOBBLE_AMP  := 5.0
const SELECTION_TOP_Y       := -44.0
const SELECTION_TRI_H       := 10.0

# Lightning rendering
const LIGHTNING_START_Y  := -500.0
const LIGHTNING_SEGMENTS := 6
const LIGHTNING_THRESHOLD:= 0.8

# Slipstream rendering
const SLIPSTREAM_LINE_WIDTH := 1.5
const SLIPSTREAM_LINE_COUNT := 3
const SLIPSTREAM_ANIM_SPEED := 15.0
const SLIPSTREAM_ANIM_PHASE := 2.1
const SLIPSTREAM_SCROLL_MOD := 40.0
const SLIPSTREAM_LEN_BASE   := 25.0
const SLIPSTREAM_LEN_BONUS  := 0.2
