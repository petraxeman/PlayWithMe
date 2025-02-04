extends Node
class_name GameObj

var uuid: String
var memory: Array = []
var story_name: String = ""

var setting: String = ""
var additional: String = ""

var hero_name: String = ""
var hero_desc: String = ""

var scenes: Array = []
var chat: Array = []

var active_choices = []



func _init():
	uuid = UUID.v4()


func save_game():
	var data = {
		"uuid": uuid,
		"memory": memory,
		"story_name": story_name,
		"setting": setting,
		"additional": additional,
		"hero_name": hero_name,
		"hero_desc": hero_desc,
		"scenes": scenes,
		"chat": chat,
		"active_choices": active_choices
	}
	var datas = JSON.stringify(data)
	var save_file = FileAccess.open("user://saves/%s.save" % uuid, FileAccess.WRITE)
	save_file.store_string(datas)


func load_game(filename: String):
	var save_file = FileAccess.open("user://saves/%s" % filename, FileAccess.READ)
	var data = JSON.parse_string(save_file.get_as_text())
	uuid = data["uuid"]
	memory = data["memory"]
	story_name = data.get("story_name", "This story without name")
	setting = data["setting"]
	additional = data["additional"]
	hero_name = data["hero_name"]
	hero_desc = data["hero_desc"]
	
	scenes = data["scenes"]
	chat = data["chat"]
	
	active_choices = data["active_choices"]
