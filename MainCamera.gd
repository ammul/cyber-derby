extends Camera2D

@export var smoothing: float = GameConfig.CAMERA_SMOOTHING
@export var lead_offset: float = GameConfig.CAMERA_LEAD_OFFSET

@onready var track: RaceTrack = $".."


func _process(_delta: float) -> void:
	var horses := get_tree().get_nodes_in_group(GameConfig.GROUP_HORSES)
	if horses.is_empty() or not track.race_started:
		return

	var lead_x := -INF
	for horse: Node2D in horses:
		if horse.position.x > lead_x:
			lead_x = horse.position.x

	var target_x := lead_x + lead_offset
	if position.x < target_x:
		position.x = lerp(position.x, target_x, smoothing)
