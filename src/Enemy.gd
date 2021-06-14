extends KinematicBody

export var left_offset: float = 0.0

var vel := Vector3()

onready var player = get_node("/root/Main/Player")
var path_follow_node = null
var aggro: bool = false

func _ready():
	$HeadPivot/FeetSensor.add_exception(self)
	path_follow_node = get_node("/root/Main/Level/CarabanPath").get_node(name)
	global_transform.origin = path_follow_node.global_transform.origin

func trap():
	$TrapTimer.start()

func _physics_process(delta):
	# search for enemies
	if not aggro:
		for b in $HeadPivot/Head/SightArea.get_overlapping_bodies():
			if not b.is_in_group("players"):
				continue
			var space_state = get_world().direct_space_state
			# use global coordinates, not local to node
			var result = space_state.intersect_ray($HeadPivot/Head/SightArea.global_transform.origin, b.global_transform.origin, [self])
			if result != null:
				aggro = true
				$GunshotTimer.start()
				$AggroLoopPlayer.play()
	
	var target = path_follow_node.global_transform.origin + -left_offset*path_follow_node.global_transform.basis.z
	if aggro:
		target = player.global_transform.origin
	vel.y -= 30.0*delta
	var movement = (target - global_transform.origin).normalized() * 10.0
	if not $TrapTimer.is_stopped():
		movement = Vector3()
	movement.y = 0.0
	if $HeadPivot/FeetSensor.is_colliding() and is_on_floor():
		vel.y = 15.0
	vel.x = lerp(vel.x, movement.x, delta*5.0)
	vel.z = lerp(vel.z, movement.z, delta*5.0)
	vel = move_and_slide(vel, Vector3(0.0, 1.0, 0.0))
	if target.distance_to(global_transform.origin) > 0.1:
		$Eye.look_at(target, Vector3(0.0, 1.0, 0.0))
	$HeadPivot.rotation.y = lerp_angle($HeadPivot.rotation.y, $Eye.rotation.y + PI, delta*3.0)


func _on_GunshotTimer_timeout():
	$GunshotSoundEffect.play()
	var space_state = get_world().direct_space_state
	# use global coordinates, not local to node
	var result = space_state.intersect_ray($HeadPivot/Head.global_transform.origin, player.global_transform.origin, [self])
	
	if result["collider"].is_in_group("players") and result != null:
		player.damage()
