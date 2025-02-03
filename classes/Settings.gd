extends Node
class_name Settings

var aimodel = ""
var aitoken = ""
var aiendpoint = ""

var language = ""
var theme = ""


func load_settings():
	var file = FileAccess.open("user://settings.json", FileAccess.READ)
	var data = {}
	
	if file:
		var content = file.get_as_text()
		file.close()
		data = JSON.parse_string(content)
	
	aimodel = data.get("aimodel", "gemini")
	aitoken = data.get("aitoken", "")
	aiendpoint = data.get("aiendpoint", "")
	
	language = data.get("language", "en")
	theme = data.get("theme", "NightlyDog.tres")


func dump_settings():
	var file = FileAccess.open("user://settings.json", FileAccess.WRITE)
	var data = {
		"aimodel": aimodel,
		"aitoken": aitoken,
		"aiendpoint": aiendpoint,
		"language": language,
		"theme": theme
	}
	
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
