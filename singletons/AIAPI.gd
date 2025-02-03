extends Node

var http: HTTPRequest

var return_format = """

"""

var start_game_query = """
Сеттинг: {setting}
Дополнительно: {additional}
Имя главного героя: {hero_name}
Описание главного героя: {hero_desc}

Твоя задача сейчас придумать начало для истории.
Верни ответ в формате JSON.

Пример:
{
	"story_name": "Название истории",
	"remember": "Коротко укажи тут информацию которую ты бы хотел запомнить для следующих сцен. Одно или максимум два предложения",
	"text": "Тут напиши основной текст сцены.",
	"choices": [{"text": "Выбор 1", "dificult": "elementary"}, {"text": "Выбор 1", "dificult": "medium"}]
}
У каждого выбора сложность может быть следующей:
"elementary" - Невозможно провалить это действие
"easy" - Низкий шанс на провал
"medium" - Средний шанс на провал
"hard" - Высокий шанс провала
"""

var choice_game_query = """
Сеттинг: {setting}
Дополнительно: {additional}
Имя главного героя: {hero_name}
Описание главного героя: {hero_desc}

Ты просил запомнить для тебя следующую информациб: {memory}
Предыдущие сцены (не больще 3): {prev_scene}

Игрок решил сделать: {choice}
Верни ответ в формате JSON.

Пример:
{
	"story_name": "Название истории",
	"remember": "Коротко укажи тут информацию которую ты бы хотел запомнить для следующих сцен. Одно или максимум два предложения",
	"text": "Тут напиши основной текст сцены.",
	"choices": [{"text": "Выбор 1", "dificult": "elementary"}, {"text": "Выбор 1", "dificult": "medium"}]
}
У каждого выбора сложность может быть следующей:
"elementary" - Невозможно провалить это действие
"easy" - Низкий шанс на провал
"medium" - Средний шанс на провал
"hard" - Высокий шанс провала
"""


func _ready():
	http = HTTPRequest.new()
	get_node("/root/Aiapi").add_child(http)


func gen_start_game(hero_name: String, hero_description: String, setting: String, additional: String = ""):
	var query = start_game_query.format({"setting": setting, "additional": additional, "hero_name": hero_name, "hero_desc": hero_description})
	var resp = await Globals.chatbot.ask(query)
	return resp


func gen_cont_game(choice: String):
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
		}
	var query = choice_game_query.format(data)
	var resp = await Globals.chatbot.ask(query)
	return resp
