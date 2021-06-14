extends Area

var used = false

func _on_BearTrap_body_entered(body):
	if not used and body.is_in_group("people"):
		used = true
		$AudioStreamPlayer3D.play()
		body.trap()
		$BeartrapMesh/AnimationPlayer.play("close")
