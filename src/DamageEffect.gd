extends ColorRect

func _process(delta):
	color.a = lerp(color.a, 0.0, delta*2.0)
