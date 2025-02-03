extends Control

var message_pack = preload("res://scenes/message.tscn")
var choice_pack = preload("res://scenes/choice.tscn")
var memory_row_pack = preload("res://scenes/memory_row.tscn")

var rng = RandomNumberGenerator.new()


func _ready():
	$vbox/scroll.size_flags_stretch_ratio = 6
	$vbox/actions.size_flags_stretch_ratio = 1
	await get_tree().create_timer(0.01).timeout.connect(func () -> void: render_choices())
	slide_down()


func start():
	var cg = Globals.current_game
	var resp = await Aiapi.gen_start_game(cg.hero_name, cg.hero_desc, cg.setting, cg.additional)
	
	Globals.current_game.memory.append(resp["remember"])
	Globals.current_game.chat.append({"role": "assistant", "text": resp["text"]})
	Globals.current_game.active_choices = resp["choices"]
	Globals.current_game.story_name = resp["story_name"]
	
	var message = message_pack.instantiate()
	message.set_text(resp["text"])
	$vbox/scroll/vbox.add_child(message)
	
	Globals.current_game.save_game()


func continue_game():
	for message in Globals.current_game.chat:
		if message["role"] == "assistant":
			var msg_scene = message_pack.instantiate()
			msg_scene.set_text(message["text"])
			$vbox/scroll/vbox.add_child(msg_scene)
		elif message["role"] == "user":
			var msg_scene = message_pack.instantiate()
			msg_scene.set_text(message["text"])
			$vbox/scroll/vbox.add_child(msg_scene)


func choice(text: String, dificult: String):
	var threshold: int = 0
	match dificult:
		"easy":
			threshold = 20
		"medium":
			threshold = 50
		"hard":
			threshold = 80
	
	var check: int = rng.randi_range(0, 100)
	var check_result: String = "(Не получилось выполнить)"
	if check >= threshold:
		check_result = "(Получилось выполнить)"
	
	var ch_msg = choice_pack.instantiate()
	ch_msg.set_text(text + " " + check_result)
	$vbox/scroll/vbox.add_child(ch_msg)
	Globals.current_game.chat.append({"role": "user", "text": text + " " + check_result})
	
	slide_down()
	
	for child in $vbox/actions.get_children():
		child.disabled = true
	
	var cg = Globals.current_game
	var resp = await Aiapi.gen_cont_game(text + " " + check_result)
	
	Globals.current_game.memory.append(resp["remember"])
	Globals.current_game.chat.append({"role": "assistant", "text": resp["text"]})
	Globals.current_game.active_choices = resp["choices"]
	
	var message = message_pack.instantiate()
	message.set_text(resp["text"])
	$vbox/scroll/vbox.add_child(message)
	
	Globals.current_game.save_game()
	
	slide_down()
	render_choices()


func slide_down():
	get_tree().create_timer(0.01).timeout.connect(
		func () -> void: $vbox/scroll.scroll_vertical = $vbox/scroll.get_v_scroll_bar().max_value
	)


func _on_info_open_pressed():
	$info_panel.reset_size()
	
	var sz = DisplayServer.screen_get_size()
	var mult = 2.5
	sz = Vector2i(int(sz.x / mult), int(sz.y / mult))
	
	var cg = Globals.current_game
	$info_panel/scroll/margin/vbox/main/hero_name.text = cg.hero_name if cg.hero_name else "-"
	$info_panel/scroll/margin/vbox/main/hero_desc.text = cg.hero_desc if cg.hero_desc else "-"
	$info_panel/scroll/margin/vbox/main/settings.text = cg.setting if cg.setting else "-"
	$info_panel/scroll/margin/vbox/main/additional.text = cg.additional if cg.additional else "-"
	$info_panel/scroll/margin/vbox/main/story_name.text = cg.story_name if cg.story_name else "-"
	
	render_memory()
	
	$info_panel.set_size(sz)
	$info_panel.show()


func render_memory():
	var cg = Globals.current_game
	for child in $info_panel/scroll/margin/vbox/memory/rows.get_children():
		child.queue_free()
	
	for row in cg.memory:
		var mrow = memory_row_pack.instantiate()
		mrow.set_text(row)
		mrow.delete.connect(delete_memory)
		$info_panel/scroll/margin/vbox/memory/rows.add_child(mrow)


func render_choices():
	for child in $vbox/actions.get_children():
		child.queue_free()
	
	for ch in Globals.current_game.active_choices:
		var btn = Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL#$ + Control.SIZE_SHRINK_CENTER
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.text = ch["text"]
		btn.tooltip_text = "Сложность: " + ch["dificult"]
		btn.pressed.connect(choice.bind(ch["text"], ch["dificult"]))
		$vbox/actions.add_child(btn)
		btn.hide()
	
	await get_tree().create_timer(0.01).timeout.connect( func () -> void: 
		for child in $vbox/actions.get_children(): child.show()
	)

func delete_memory(text: String):
	var i = Globals.current_game.memory.find(text)
	if i == -1:
		return
	Globals.current_game.memory.pop_at(i)
	render_memory()


func _on_exit_pressed():
	Globals.current_game.save_game()
	Globals.current_game = null
	Globals.chatbot = null
	var main_menu_scene = load("res://scenes/main_menu.tscn").instantiate()
	get_tree().root.add_child(main_menu_scene)
	queue_free()
