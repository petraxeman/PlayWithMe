extends Control

var message_pack = preload("res://scenes/message.tscn")
var choice_pack = preload("res://scenes/choice.tscn")
var memory_row_pack = preload("res://scenes/memory_row.tscn")

var rng = RandomNumberGenerator.new()


func _ready():
	$vbox/scroll.size_flags_stretch_ratio = 6
	$vbox/actions.size_flags_stretch_ratio = 1
	await get_tree().create_timer(0.1).timeout.connect(func () -> void: render_choices())
	slide_down()


func start():
	var cg = Globals.current_game
	var resp = await Aiapi.gen_start_game(cg.hero_name, cg.hero_desc, cg.setting, cg.additional)
	
	parse_and_apply_events(resp["events"])
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
	$vbox/custom_input/edit.text = ""
	var threshold: int = 0
	match dificult:
		"easy":
			threshold = 20
		"medium":
			threshold = 50
		"hard":
			threshold = 80
		
	
	var check: int = rng.randi_range(0, 100)
	var check_result: String = "Не получилось выполнить"
	if check >= threshold:
		check_result = "Получилось выполнить"
	if dificult == "undefined":
		check_result = "Неизвестно"
		
	var usr_msg = "{text} ({check_result})".format({"text": text, "check_result": check_result})
	var ch_msg = choice_pack.instantiate()
	ch_msg.set_text(usr_msg)
	$vbox/scroll/vbox.add_child(ch_msg)
	Globals.current_game.chat.append({"role": "user", "text": usr_msg})
	
	slide_down()
	
	for child in $vbox/actions.get_children():
		child.disabled = true
	$vbox/custom_input/enter.disabled = true
	
	var cg = Globals.current_game
	var resp = await Aiapi.gen_cont_game(text, check_result)
	
	parse_and_apply_events(resp["events"])
	Globals.current_game.memory.append(resp["remember"])
	Globals.current_game.chat.append({"role": "assistant", "text": resp["text"]})
	Globals.current_game.active_choices = resp["choices"]
	
	var message = message_pack.instantiate()
	message.set_text(resp["text"])
	$vbox/scroll/vbox.add_child(message)
	
	Globals.current_game.save_game()
	
	slide_down()
	render_choices()
	$vbox/custom_input/enter.disabled = false


func parse_and_apply_events(events: Array):
	for event in events:
		if event is Dictionary:
			continue
		match event[0]:
			"add_character_info":
				var character_data = Globals.current_game.characters.get(event[1], [])
				character_data.append(event[2])
				Globals.current_game.characters[event[1]] = character_data
			"add_item":
				Globals.current_game.inventory[event[1]] = event[2]
			"sub_item":
				Globals.current_game.inventory.erase(event[1])


func slide_down():
	get_tree().create_timer(0.01).timeout.connect(
		func () -> void: $vbox/scroll.scroll_vertical = $vbox/scroll.get_v_scroll_bar().max_value
	)


func _on_info_open_pressed():
	$info_panel.reset_size()
	
	var sz = DisplayServer.screen_get_size()
	var mult = 2
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


func _on_enter_custom_choice_pressed():
	
	choice($vbox/custom_input/edit.text, "undefined")


func _on_inventary_open_pressed() -> void:
	for child in $inv_panel/scroll/margin/vbox/items.get_children():
		child.queue_free()
	
	for item in Globals.current_game.inventory:
		var row = HBoxContainer.new()
		var item_delete_btn = Button.new()
		var item_name_label = Label.new()
		var item_desc_label = Label.new()
		item_delete_btn.text = "Удалить"
		item_delete_btn.pressed.connect(del_item.bind(item))
		item_name_label.text = " | " + item + " | "
		item_desc_label.text = Globals.current_game.inventory[item]
		item_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item_desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(item_delete_btn)
		row.add_child(item_name_label)
		row.add_child(item_desc_label)
		$inv_panel/scroll/margin/vbox/items.add_child(row)
	
	if Globals.current_game.inventory.is_empty():
		var label = Label.new()
		label.text = "Увы, но у вас нет предметов"
		$inv_panel/scroll/margin/vbox/items.add_child(label)
	
	$inv_panel.show()


func del_item(item_name: String):
	Globals.current_game.inventory.erase(item_name)
	_on_inventary_open_pressed()


func _on_chars_info_open_pressed() -> void:
	for child in $char_panel/scroll/margin/vbox/items.get_children():
		child.queue_free()
	
	for char in Globals.current_game.characters:
		var row = HBoxContainer.new()
		var title = Label.new()
		var column = VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for info in Globals.current_game.characters[char]:
			var info_row = Label.new()
			info_row.text = info
			info_row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			info_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			column.add_child(info_row)
		title.text = char + " | "
		row.add_child(title)
		row.add_child(column)
		$char_panel/scroll/margin/vbox/items.add_child(row)
	
	if Globals.current_game.characters.is_empty():
		var label = Label.new()
		label.text = "Увы, но у вас нет никакой информации"
		$char_panel/scroll/margin/vbox/items.add_child(label)
	
	$char_panel.show()
		
