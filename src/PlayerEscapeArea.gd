extends Area



func _on_PlayerEscapeArea_body_entered(body):
	if body.is_in_group("players") and body.got_target:
		get_tree().change_scene("res://Win.tscn")
