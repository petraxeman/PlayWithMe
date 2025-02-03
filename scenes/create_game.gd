extends Control

var game_view_packed = preload("res://scenes/game_view.tscn")



func _on_start_pressed():
	var game = GameObj.new()
	game.hero_name = $vbox/hero_name/vbox/edit.text
	game.hero_desc = $vbox/hero_desc/vbox/edit.text
	game.setting = $vbox/setting/vbox/edit.text
	game.additional = $vbox/additional/vbox/edit.text
	
	
	if not game.hero_name or not game.setting:
		return
	
	Globals.current_game = game
	if Globals.settings.aimodel == "gemini":
		Globals.chatbot = GeminiAPI.new(Globals.settings.aitoken)
	
	var game_view_scene = game_view_packed.instantiate()
	game_view_scene.start()
	get_tree().root.add_child(game_view_scene)
	queue_free()
	


func _on_cancel_pressed():
	var main_menu_scene = load("res://scenes/main_menu.tscn").instantiate()
	get_tree().root.add_child(main_menu_scene)
	queue_free()
