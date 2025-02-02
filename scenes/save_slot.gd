extends PanelContainer

signal select
signal delete

var filename: String



func set_save_data(n: String, fn: String, timestamp: int):
	$margin/hbox/name.text = n
	filename = fn
	
	var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
	var dtstr = "{day}.{month}.{year} {hour}:{minute}.{second}".format(datetime)
	$margin/hbox/time.text = dtstr


func _on_choice_pressed():
	emit_signal("select", filename)


func _on_delete_pressed():
	emit_signal("delete", self, filename)
