extends KinematicBody

signal damaged

var vel := Vector3()
var movement := Vector3()
var bear_traps = 5
var health = 1.0
var pickpocket_progress = 0.0
var got_target = false

var health_regen_timer = 0.0

func damage():
	emit_signal("damaged")
	health_regen_timer = 0.0
	health -= 0.25
	if health <= 0.01:
		get_tree().change_scene("res://Lose.tscn")

func _ready():
	$CameraPivot/Camera/PlaceRayCast.add_exception(self)

func _input(event):
	# mouse capturing
	var not_captured = Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("g_focus"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("g_escape"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if not_captured:
		return
	
	# trap placement
	if $CameraPivot/Camera/PlaceRayCast.is_colliding() and \
	$CameraPivot/Camera/PlaceRayCast.get_collision_normal().dot(Vector3(0.0, 1.0, 0.0)) > 0.9 and \
	bear_traps > 0 and \
	event.is_action_pressed("g_place_trap"):
		bear_traps -= 1
		var new_trap = preload("res://BearTrap.tscn").instance()
		get_node("/root/Main/Traps").add_child(new_trap)
		new_trap.global_transform.origin = $CameraPivot/Camera/PlaceRayCast.get_collision_point()
	
	# movement of camera
	elif event is InputEventMouseMotion:
		var mouse_movement: Vector2 = event.relative * 0.007
		$CameraPivot.rotation.y -= mouse_movement.x
		$CameraPivot/Camera.rotation.x = clamp($CameraPivot/Camera.rotation.x, -PI/2.0, PI/2.0)
		$CameraPivot/Camera.rotation.x -= mouse_movement.y

func trap():
	$TrapTimer.start()

func _physics_process(delta):
	if health_regen_timer >= 3.0:
		health += delta*0.1
	health_regen_timer += delta
	health = clamp(health, 0.0, 1.0)
	var pickpocket_area = $CameraPivot/Camera/PickpocketArea
	var pickpocketing = false
	if Input.is_action_pressed("g_pickpocket") and not got_target:
		for a in pickpocket_area.get_overlapping_areas():
			if a.is_in_group("pickpocket_targets"):
				var space_state = get_world().direct_space_state
				# use global coordinates, not local to node
				var result = space_state.intersect_ray($CameraPivot/Camera.global_transform.origin, a.global_transform.origin, [self, $CameraPivot/Camera/PickpocketArea], 0x7FFFFFFF, true, true)
				if result != null:
					pickpocketing = true
					break
	if pickpocketing:
		pickpocket_progress += delta/3.0
	else:
		pickpocket_progress = 0.0
	if pickpocket_progress >= 1.0:
		got_target = true
	
	var forward: Vector3 = -$CameraPivot/Camera.global_transform.basis.z
	var right: Vector3 = $CameraPivot/Camera.global_transform.basis.x
	var new_movement := (Input.get_action_strength("g_right") - Input.get_action_strength("g_left"))*right + \
		(Input.get_action_strength("g_forward") - Input.get_action_strength("g_backward"))*forward
	if not $TrapTimer.is_stopped():
		new_movement = Vector3()
	new_movement = new_movement.normalized() * 18.0
	movement = lerp(movement, new_movement, 20.0*delta)
	if Input.is_action_just_pressed("g_jump") and is_on_floor():
		vel.y = 14.0
#	if new_movement.length() > 0.1:
	vel.x = lerp(vel.x, movement.x, delta*9.0)
	vel.z = lerp(vel.z, movement.z, delta*9.0)
	vel.y -= 30.0*delta
	vel = move_and_slide(vel, Vector3(0.0, 1.0, 0.0))
