extends Node

var http: HTTPRequest

var return_format = """

"""

var start_game_query = """
Сеттинг: {setting}
Дополнительно: {additional}
Имя главного героя за которого играет игрок: {hero_name}
Описание главного героя: {hero_desc}

Твоя задача сейчас придумать начало для истории.
Верни ответ в формате JSON.

Пример:
{
	"story_name": "Название истории",
	"remember": "Коротко укажи тут информацию которую ты бы хотел запомнить для следующих сцен. Одно или максимум два предложения",
	"text": "Тут напиши основной текст сцены.",
	"choices": [{"text": "Выбор 1", "dificult": "elementary"}, {"text": "Выбор 1", "dificult": "medium"}]
	"events": [
		["add_character_info", "Имя персонажа", "Какая то информация о нем."],
		["add_item", "Название предмета", "Описание предмета"]
	]
}

У каждого выбора сложность может быть следующей:
"elementary" - Невозможно провалить это действие
"easy" - Низкий шанс на провал
"medium" - Средний шанс на провал
"hard" - Высокий шанс провала

Если ты хочешь добавить информацию о персонаже, или предмет в инвентарь игроку, просто впиши соответсвующий event в поле events.
Поле events может быть пустым если ты ничего не хочешь добавлять. Не злоупотребляй этим полем.
"""

var choice_game_query = """
Сеттинг: {setting}
Дополнительно: {additional}
Имя главного героя за которого играет игрок: {hero_name}
Описание главного героя: {hero_desc}

Ты просил запомнить для тебя следующую информациб: {memory}
Предыдущие сцены (не больще 3): {prev_scene}

Игрок решил сделать: {choice}
Получилось ли у него сделать это: {check_result}

Верни ответ в формате JSON.

Пример:
{
	"story_name": "Название истории",
	"remember": "Коротко укажи тут информацию которую ты бы хотел запомнить для следующих сцен. Одно или максимум два предложения",
	"text": "Тут напиши основной текст сцены.",
	"choices": [{"text": "Выбор 1", "dificult": "elementary"}, {"text": "Выбор 1", "dificult": "medium"}]
	"events": [
		["add_character_info", "Имя персонажа", "Какая то информация о нем."],
		["add_item", "Название предмета", "Описание предмета"]
	]
}
У каждого выбора сложность может быть следующей:
"elementary" - Невозможно провалить это действие
"easy" - Низкий шанс на провал
"medium" - Средний шанс на провал
"hard" - Высокий шанс провала

Если ты хочешь добавить информацию о персонаже, или предмет в инвентарь игроку, просто впиши соответсвующий event в поле events.
Поле events может быть пустым если ты ничего не хочешь добавлять. Не злоупотребляй этим полем.
"""


func _ready():
	http = HTTPRequest.new()
	get_node("/root/Aiapi").add_child(http)


func gen_start_game(hero_name: String, hero_description: String, setting: String, additional: String = ""):
	var query = start_game_query.format({"setting": setting, "additional": additional, "hero_name": hero_name, "hero_desc": hero_description})
	
	var characters_query = "Список персонажей учавствовавших в истории, и их черты:"
	for character in Globals.current_game.characters:
		characters_query += """
		---
		Имя персонажа: {character_name}
		Черты персонажа:
		{character_desc}
		""".format({"character_name": character, "character_desc": "\n".join(Globals.current_game.characters[character])})
	
	var inventory_query = "Список всех предметов в инвентаре главного героя:"
	for item in Globals.current_game.inventory:
		inventory_query += """
		{item_name} - {item_desc}
		""".format({"item_name": item, "item_desc": Globals.current_game.inventory[item]})
	
	var resp = await Globals.chatbot.ask(characters_query + inventory_query + query)
	return resp


func gen_cont_game(choice: String, check_result: String):
	var cg = Globals.current_game
	
	var last_scenes = []
	for i in range(cg.chat.size() - 1, -1, -1):
		if cg.chat[i]["role"] == "assistant":
			last_scenes.append(cg.chat[i]["text"])
		
		if last_scenes.size() >= 3:
			break
	
	last_scenes.reverse()
	
	var data = {
		"setting": cg.setting,
		"additional": cg.additional,
		"hero_name": cg.hero_name,
		"hero_desc": cg.hero_desc,
		"memory": ", ".join(cg.memory),
		"prev_scene": "\n".join(last_scenes),
		"choice": choice,
		"check_result": check_result
		}
	
	var query = choice_game_query.format(data)
	
	var characters_query = "Список персонажей учавствовавших в истории, и их черты:"
	for character in Globals.current_game.characters:
		characters_query += """
		---
		Имя персонажа: {character_name}
		Черты персонажа:
		{character_desc}
		""".format({"character_name": character, "character_desc": "\n".join(Globals.current_game.characters[character])})
	
	var inventory_query = "Список всех предметов в инвентаре главного героя:"
	for item in Globals.current_game.inventory:
		inventory_query += """
		{item_name} - {item_desc}
		""".format({"item_name": item, "item_desc": Globals.current_game.inventory[item]})
	
	var resp = await Globals.chatbot.ask(characters_query + inventory_query + query)
	return resp
