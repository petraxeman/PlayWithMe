extends Node

var settings: Settings
var chatbot: AbsChatbot
var urlmod: HTTPRequest
var current_game: GameObj



func _ready():
	settings = Settings.new()
	settings.load_settings()
	
	if not DirAccess.dir_exists_absolute("user://saves"):
		DirAccess.make_dir_absolute("user://saves")


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		settings.dump_settings()


func load_chatbot():
	if settings.aimodel == "gemini":
		chatbot = GeminiAPI.new(Globals.settings.aitoken)
