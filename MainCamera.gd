extends Camera2D

@export var smoothing: float = 0.005
@export var lead_offset: float = 200.0 # Wie viel Platz lassen wir vor dem ersten Pferd?

@onready var track = $".."

func _process(_delta):
	var horses = get_tree().get_nodes_in_group("horses")
	if horses.is_empty() or not track.race_started: return

	# 1. Das führende Pferd finden (höchster X-Wert)
	var lead_x = -INF
	for horse in horses:
		if horse.position.x > lead_x:
			lead_x = horse.position.x
	
	# 2. Zielposition berechnen
	# Wir wollen das Pferd nicht in der Mitte, sondern links sehen,
	# damit wir rechts (vorne) Platz zum Klicken haben.
	var target_x = lead_x + lead_offset
	
	# 3. Sanfte Verfolgung (Interpolation)
	if position.x < target_x:
		position.x = lerp(position.x, target_x, smoothing)
