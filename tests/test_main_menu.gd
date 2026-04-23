extends GutTest

func test_scene_path_constants_exist() -> void:
	assert_eq(GameConfig.SCENE_MAIN_MENU, "res://MainMenu.tscn",
		"GameConfig.SCENE_MAIN_MENU must point to MainMenu.tscn")
	assert_eq(GameConfig.SCENE_RACE_TRACK, "res://RaceTrack.tscn",
		"GameConfig.SCENE_RACE_TRACK must point to RaceTrack.tscn")

func test_main_menu_scene_loads() -> void:
	var scene: PackedScene = load(GameConfig.SCENE_MAIN_MENU)
	assert_not_null(scene, "MainMenu.tscn must be loadable as a PackedScene")

func test_main_menu_has_start_button() -> void:
	var scene: PackedScene = load(GameConfig.SCENE_MAIN_MENU)
	var instance: Control = scene.instantiate()
	add_child_autofree(instance)
	await get_tree().process_frame
	var btn := instance.get_node_or_null("CenterContainer/VBox/StartButton")
	assert_not_null(btn, "MainMenu must contain node at CenterContainer/VBox/StartButton")
	assert_true(btn is Button, "StartButton must be a Button node")

func test_start_button_text() -> void:
	var scene: PackedScene = load(GameConfig.SCENE_MAIN_MENU)
	var instance: Control = scene.instantiate()
	add_child_autofree(instance)
	await get_tree().process_frame
	var btn: Button = instance.get_node("CenterContainer/VBox/StartButton")
	assert_eq(btn.text, "STARTEN")
