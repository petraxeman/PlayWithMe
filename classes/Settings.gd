extends Node
class_name Settings

var aimodel = ""
var aitoken = ""



func load_settings():
	var file = FileAccess.open("user://settings.json", FileAccess.READ)
	var data = {}
	
	if file:
		var content = file.get_as_text()
		file.close()
		data = JSON.parse_string(content)
	
	aimodel = data.get("aimodel", "gemini")
	aitoken = data.get("aitoken", "")


func dump_settings():
	var file = FileAccess.open("user://settings.json", FileAccess.WRITE)
	var data = {
		"aimodel": aimodel,
		"aitoken": aitoken
	}
	
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
