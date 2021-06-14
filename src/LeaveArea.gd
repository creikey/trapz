extends Area



func _on_LeaveArea_body_entered(body):
	if body.is_in_group("enemies"):
		body.queue_free()
