extends Node

const top = 1
const bottom = 2
const left = 3
const right = 4
const forward = 5
const backward = 6

onready var first_person_camera = self.get_node('Player/PlayerMesh/FirstPersonCamera')
onready var third_person_camera_rotator = self.get_node('Player/PlayerMesh/ThirdPersonCameraRotator')
onready var third_person_camera = self.get_node('Player/PlayerMesh/ThirdPersonCameraRotator/ThirdPersonCamera')
onready var crossair = self.get_node('Player/PlayerMesh/Crossair')
onready var player_mesh = self.get_node('Player/PlayerMesh')
onready var player = self.get_node('Player')

onready var targeted_surface_indicator = self.get_node('TargetedSurface')

var mouse_locked = true

var flying = true

const block_place_delay = 200
const block_break_delay = 200
var block_placed_at = 0
var block_breaked_at = 0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	var player_forward = -player_mesh.get_global_transform().basis.z
	var player_backward = player_mesh.get_global_transform().basis.z
	var player_left = -player_mesh.get_global_transform().basis.x
	var player_right = player_mesh.get_global_transform().basis.x

	if Input.is_action_pressed('W'):
		Physic.add_velocity(Physic.player_move_velocity, Physic.move_velocity_add * player_forward.x * delta, 0, Physic.move_velocity_add * player_forward.z * delta, 80)
	if Input.is_action_pressed('A'):
		Physic.add_velocity(Physic.player_move_velocity, Physic.move_velocity_add * player_left.x * delta, 0, Physic.move_velocity_add * player_left.z * delta, 80)
	if Input.is_action_pressed('S'):
		Physic.add_velocity(Physic.player_move_velocity, Physic.move_velocity_add * player_backward.x * delta, 0, Physic.move_velocity_add * player_backward.z * delta, 80)
	if Input.is_action_pressed('D'):
		Physic.add_velocity(Physic.player_move_velocity, Physic.move_velocity_add * player_right.x * delta, 0, Physic.move_velocity_add * player_right.z * delta, 80)
	if flying:
		if Input.is_action_pressed('Space'):
			Physic.add_velocity(Physic.player_move_velocity, 0, Physic.move_velocity_add * delta, 0, 80)
		if Input.is_action_pressed('Shift'):
			Physic.add_velocity(Physic.player_move_velocity, 0, -Physic.move_velocity_add * delta, 0, 80)
	else:
		Physic.add_velocity(Physic.player_velocity, 0, -Physic.gravity_add * delta, 0, 300)
		if Input.is_action_pressed('Space') and Physic.player_is_on_the_ground():
			Physic.add_velocity(Physic.player_velocity, 0, 100, 0, 300)
	
	Physic.move(delta)



	var camera_pos = {
		x = first_person_camera.global_translation.x,
		y = first_person_camera.global_translation.y,
		z = first_person_camera.global_translation.z
	}
	var camera_dir = {
		x = - first_person_camera.get_global_transform().basis.z.x,
		y = - first_person_camera.get_global_transform().basis.z.y,
		z = - first_person_camera.get_global_transform().basis.z.z
	}
	var targeted_block = Raycast.get_targeted_block(camera_pos, camera_dir, 80)
	if targeted_block.found:
		targeted_surface_indicator.show()
		if targeted_block.face == top:
			targeted_surface_indicator.rotation_degrees.x = 0
			targeted_surface_indicator.rotation_degrees.y = 0
			targeted_surface_indicator.rotation_degrees.z = 0
			targeted_surface_indicator.translation.x = targeted_block.previous_block.x * ChunkLoader.block_size + ChunkLoader.block_size / 2
			targeted_surface_indicator.translation.y = targeted_block.previous_block.y * ChunkLoader.block_size + 0.001
			targeted_surface_indicator.translation.z = targeted_block.previous_block.z * ChunkLoader.block_size + ChunkLoader.block_size / 2
		if targeted_block.face == bottom:
			targeted_surface_indicator.rotation_degrees.x = 0
			targeted_surface_indicator.rotation_degrees.y = 0
			targeted_surface_indicator.rotation_degrees.z = 0
			targeted_surface_indicator.translation.x = targeted_block.previous_block.x * ChunkLoader.block_size + ChunkLoader.block_size / 2
			targeted_surface_indicator.translation.y = targeted_block.previous_block.y * ChunkLoader.block_size + ChunkLoader.block_size - 0.001
			targeted_surface_indicator.translation.z = targeted_block.previous_block.z * ChunkLoader.block_size + ChunkLoader.block_size / 2
		if targeted_block.face == left:
			targeted_surface_indicator.rotation_degrees.x = 0
			targeted_surface_indicator.rotation_degrees.y = 0
			targeted_surface_indicator.rotation_degrees.z = 90
			targeted_surface_indicator.translation.x = targeted_block.previous_block.x * ChunkLoader.block_size + ChunkLoader.block_size - 0.001
			targeted_surface_indicator.translation.y = targeted_block.previous_block.y * ChunkLoader.block_size + ChunkLoader.block_size / 2
			targeted_surface_indicator.translation.z = targeted_block.previous_block.z * ChunkLoader.block_size + ChunkLoader.block_size / 2
		if targeted_block.face == right:
			targeted_surface_indicator.rotation_degrees.x = 0
			targeted_surface_indicator.rotation_degrees.y = 0
			targeted_surface_indicator.rotation_degrees.z = -90
			targeted_surface_indicator.translation.x = targeted_block.previous_block.x * ChunkLoader.block_size + 0.001
			targeted_surface_indicator.translation.y = targeted_block.previous_block.y * ChunkLoader.block_size + ChunkLoader.block_size / 2
			targeted_surface_indicator.translation.z = targeted_block.previous_block.z * ChunkLoader.block_size + ChunkLoader.block_size / 2
		if targeted_block.face == forward:
			targeted_surface_indicator.rotation_degrees.x = 90
			targeted_surface_indicator.rotation_degrees.y = 0
			targeted_surface_indicator.rotation_degrees.z = 0
			targeted_surface_indicator.translation.x = targeted_block.previous_block.x * ChunkLoader.block_size + ChunkLoader.block_size / 2
			targeted_surface_indicator.translation.y = targeted_block.previous_block.y * ChunkLoader.block_size + ChunkLoader.block_size / 2
			targeted_surface_indicator.translation.z = targeted_block.previous_block.z * ChunkLoader.block_size + 0.001
		if targeted_block.face == backward:
			targeted_surface_indicator.rotation_degrees.x = -90
			targeted_surface_indicator.rotation_degrees.y = 0
			targeted_surface_indicator.rotation_degrees.z = 0
			targeted_surface_indicator.translation.x = targeted_block.previous_block.x * ChunkLoader.block_size + ChunkLoader.block_size / 2
			targeted_surface_indicator.translation.y = targeted_block.previous_block.y * ChunkLoader.block_size + ChunkLoader.block_size / 2
			targeted_surface_indicator.translation.z = targeted_block.previous_block.z * ChunkLoader.block_size + ChunkLoader.block_size - 0.001
	else:
		targeted_surface_indicator.hide()

	

	if Input.is_mouse_button_pressed(BUTTON_LEFT) and OS.get_ticks_msec() - block_breaked_at > block_break_delay:
		block_breaked_at = OS.get_ticks_msec()
		ChunkLoader.get_block(targeted_block.block.x, targeted_block.block.y, targeted_block.block.z).has_block = false
		ChunkLoader.reload_chunk_surfaces(ChunkLoader.convert_to_chunk_coordinate(targeted_block.block.x), ChunkLoader.convert_to_chunk_coordinate(targeted_block.block.z))
	if Input.is_mouse_button_pressed(BUTTON_RIGHT) and OS.get_ticks_msec() - block_placed_at > block_place_delay:
		block_placed_at = OS.get_ticks_msec()
		ChunkLoader.get_block(targeted_block.previous_block.x, targeted_block.previous_block.y, targeted_block.previous_block.z).has_block = true
		ChunkLoader.reload_chunk_surfaces(ChunkLoader.convert_to_chunk_coordinate(targeted_block.previous_block.x), ChunkLoader.convert_to_chunk_coordinate(targeted_block.previous_block.z))
	if Input.is_action_just_pressed('L'):
		var light = OmniLight.new()
		light.light_energy = 0.8
		light.shadow_enabled = true 
		light.omni_range = 890
		light.translation.x = targeted_block.previous_block.x * ChunkLoader.block_size + ChunkLoader.block_size / 2
		light.translation.y = targeted_block.previous_block.y * ChunkLoader.block_size + ChunkLoader.block_size / 2
		light.translation.z = targeted_block.previous_block.z * ChunkLoader.block_size + ChunkLoader.block_size / 2
		add_child(light)



	var player_chunk_position = {
		x = floor(player.translation.x / ChunkLoader.chunk_size / ChunkLoader.block_size),
		y = floor(player.translation.y / ChunkLoader.chunk_size / ChunkLoader.block_size),
		z = floor(player.translation.z / ChunkLoader.chunk_size / ChunkLoader.block_size)
	}
	ChunkLoader.load_chunks_around_player(player_chunk_position)
	ChunkLoader.unload_chunk_far_from_player(player_chunk_position)

func _input(event):
	if event is InputEventMouseMotion:
		first_person_camera.rotation.x -= event.relative.y * 0.005
		third_person_camera_rotator.rotation.x = first_person_camera.rotation.x
		player_mesh.rotation.y -= event.relative.x * 0.005

	if event is InputEventKey and Input.is_key_pressed(KEY_F5) and not event.echo:
		if first_person_camera.current:
			first_person_camera.current = false
			third_person_camera.current = true
			crossair.hide()
		else:
			first_person_camera.current = true
			third_person_camera.current = false
			crossair.show()

	if event is InputEventKey and Input.is_key_pressed(KEY_ESCAPE) and not event.echo:
		if mouse_locked:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			mouse_locked = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_locked = true

	if event is InputEventKey and Input.is_key_pressed(KEY_F) and not event.echo:
		flying = !flying

func _exit_tree():
	Multithread.stop_all_threads()
	Multithread.wait_to_finish()
