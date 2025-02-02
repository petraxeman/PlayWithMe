extends HBoxContainer

signal delete

var text: String



func set_text(t: String):
	text = t
	$text.text = t


func _on_del_pressed():
	emit_signal("delete", text)
