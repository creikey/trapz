extends Spatial

func _process(delta):
	if get_children().size() <= 0:
		get_tree().change_scene("res://Lose.tscn")
