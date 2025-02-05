extends Control

var create_game_packed_scene = preload("res://scenes/create_game.tscn")
var game_view_pack = preload("res://scenes/game_view.tscn")
var save_slot_pack = preload("res://scenes/save_slot.tscn")



func _ready():
	print(OS.get_data_dir())
	TranslationServer.set_locale(Globals.settings.language)
	var theme_obj = load("res://assets/themes/" + Globals.settings.theme)
	get_tree().root.theme = theme_obj
#
# Main view actions handlers
#

func _on_start_pressed():
	var create_game_scene = create_game_packed_scene.instantiate()
	get_tree().root.add_child(create_game_scene)
	queue_free()


func _on_load_pressed():
	$main_view.hide()

	render_saves()
	$load.show()


func _on_settings_pressed():
	$main_view.hide()
	$settings/panel/vbox/language/option.clear()
	$settings/panel/vbox/theme/option.clear()
	
	for locale in TranslationServer.get_loaded_locales():
		$settings/panel/vbox/language/option.add_item(locale)
	for theme_ in DirAccess.get_files_at("res://assets/themes"):
		$settings/panel/vbox/theme/option.add_item(theme_)
	
	for i in $settings/panel/vbox/aimodel/option.item_count:
		var option_text = $settings/panel/vbox/aimodel/option.get_item_text(i)
		if Globals.settings.aimodel == option_text:
			$settings/panel/vbox/aimodel/option.select(i)
			break
	for i in $settings/panel/vbox/language/option.item_count:
		var option_text = $settings/panel/vbox/language/option.get_item_text(i)
		if Globals.settings.language == option_text:
			$settings/panel/vbox/language/option.select(i)
			break
	for i in $settings/panel/vbox/theme/option.item_count:
		var option_text = $settings/panel/vbox/theme/option.get_item_text(i)
		if Globals.settings.theme == option_text:
			$settings/panel/vbox/theme/option.select(i)
			break
	
	$settings/panel/vbox/aiendpoint/edit.text = Globals.settings.aiendpoint
	$settings/panel/vbox/aitoken/edit.text = Globals.settings.aitoken
	$settings.show()


func _on_exit_pressed():
	get_tree().quit()



#
# Settings view actions handler
#

func _on_save_settings_pressed():
	Globals.settings.aimodel = $settings/panel/vbox/aimodel/option.get_item_text($settings/panel/vbox/aimodel/option.selected)
	Globals.settings.aitoken = $settings/panel/vbox/aitoken/edit.text
	Globals.settings.language = $settings/panel/vbox/language/option.get_item_text($settings/panel/vbox/language/option.selected)
	Globals.settings.aiendpoint = $settings/panel/vbox/aiendpoint/edit.text
	Globals.settings.theme = $settings/panel/vbox/theme/option.get_item_text($settings/panel/vbox/theme/option.selected)
	
	var theme_obj = load("res://assets/themes/" + Globals.settings.theme)
	get_tree().root.theme = theme_obj
	TranslationServer.set_locale(Globals.settings.language)
	Globals.settings.dump_settings()
	$settings.hide()
	$main_view.show()


func _on_cancel_settings_pressed():
	$settings.hide()
	$main_view.show()



#
# Load view actions handler
#

func _on_cancel_load_pressed():
	$load.hide()
	$main_view.show()


func delete_save(obj, filename: String):
	obj.queue_free()
	var dir = DirAccess.open("user://saves")
	await dir.remove("./%s" % filename)
	render_saves()


func load_save(filename: String):
	var new_game = GameObj.new()
	new_game.load_game(filename)
	
	Globals.current_game = new_game
	Globals.load_chatbot()
	
	var game_view_scene = game_view_pack.instantiate()
	game_view_scene.continue_game()
	get_tree().root.add_child(game_view_scene)
	queue_free()


func render_saves():
	for child in $load/margin/vbox/scroll/vbox.get_children():
		child.queue_free()
	
	for filename in DirAccess.get_files_at("user://saves"):
		var file = FileAccess.open("user://saves/" + filename, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		var slot = save_slot_pack.instantiate()
		slot.set_save_data(data.get("story_name", data["hero_name"]), filename, FileAccess.get_modified_time("user://saves/" + filename))
		slot.delete.connect(delete_save)
		slot.select.connect(load_save)
		$load/margin/vbox/scroll/vbox.add_child(slot)
