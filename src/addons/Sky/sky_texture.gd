tool
extends Viewport

const material = preload("res://addons/Sky/sky_material.tres")

signal sky_updated

export (NodePath) var direction_light_path
export var sun_position = Vector3(0.0, 1.0, 0.0) setget set_sun_position, get_sun_position
export (Texture) var night_sky = null setget set_night_sky, get_night_sky
export (Basis) var rotate_night_sky = Basis() setget set_rotate_night_sky, get_rotate_night_sky

var trigger_count = 0

#######################################################################################
# properties

func set_sun_position(new_position):
	sun_position = new_position
#	print(has_node(direction_light_path))
#	printt(sun_position, sun_position.dot(Vector3(0.0, 1.0, 0.0)))
	if has_node(direction_light_path) and sun_position.normalized().dot(Vector3(0.0, 1.0, 0.0)) < 0.99:
		var direction_light = get_node(direction_light_path)
		direction_light.look_at(sun_position, Vector3(0.0, 1.0, 0.0))
		direction_light.rotate(direction_light.global_transform.basis.y, PI)
		direction_light.visible = sun_position.y > -1.0
#	print(material)
	material.set_shader_param("sun_pos", sun_position)
	_trigger_update_sky()

func get_sun_position():
	return sun_position

func set_night_sky(new_texture):
	night_sky = new_texture
	material.set_shader_param("night_sky", night_sky)
	_trigger_update_sky()

func get_night_sky():
	return night_sky

func set_rotate_night_sky(new_basis):
	rotate_night_sky = new_basis
	# set the inverse of our rotation to get the right effect
	material.set_shader_param("rotate_night_sky", rotate_night_sky.inverse())
	_trigger_update_sky()

func get_rotate_night_sky():
	return rotate_night_sky

func set_time_of_day(hours, directional_light, horizontal_angle = 0.0):
	var sun_position = Vector3(0.0, -100.0, 0.0)
	sun_position = sun_position.rotated(Vector3(1.0, 0.0, 0.0), hours * PI / 12.0)
	sun_position = sun_position.rotated(Vector3(0.0, 1.0, 0.0), horizontal_angle)
	
	if directional_light:
		var t = directional_light.transform
		t.origin = sun_position
		directional_light.transform = t.looking_at(Vector3(0.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0))
		directional_light.light_energy = 1.0 - clamp(abs(hours - 12.0) / 6.0, 0.0, 1.0)
	
	# and update our sky
	set_sun_position(sun_position)

func copy_to_environment(environment):
	# This is a bit of a hack, when the sky texture is assigned to our panorama Godot calculates a few things from the data
	# This happens just once, and it happens when the texture is assigned to the sky.
	# Unfortunately that means that if we assign our viewport texture before it renders, or if it is already assigned and
	# we update its contents, nothing renders correctly.
	# Hence we get this signal a few frames after the render has completed and we recreate a few things to force it to update
	
	# get the sky of our current camera
	var sky = environment.background_sky
	
	# first clear our texture
	sky.set_panorama(null)
	
	# with our proxy fix #18159 (Thanks ShyRed!) in place we don't need the expensive copy anymore
	sky.set_panorama(get_texture())

#######################################################################################
# internal

func _ready():
	# re-assign so our material gets updated, this will also trigger an update
	set_night_sky(night_sky)
	set_rotate_night_sky(rotate_night_sky)
	set_sun_position(sun_position)

func _trigger_update_sky():
	print("Updating")
	# trigger an update
	render_target_update_mode = Viewport.UPDATE_ONCE
	
	# delay sending out our changed signal
	trigger_count = 2

func _process(delta):
	# We don't seem to have a way to detect if the viewport has actually been updated so we just wait a few frames
	if trigger_count > 0:
		trigger_count -= 1
		if trigger_count == 0:
			emit_signal("sky_updated")
