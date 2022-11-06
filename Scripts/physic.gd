extends Node

const push_x = 1
const push_y = 2
const push_z = 3

const player_width = 8
const player_height = 16

const max_collision_push = 6

onready var player = self.get_node('/root/Game/Player')
# onready var collision_check_area = get_node('/root/Game/Test/CollisionCheckArea')

var player_move_velocity = {
	x = 0,
	y = 0,
	z = 0
}
const move_velocity_slow_down = 300
const move_velocity_add = 500
var player_velocity = {
	x = 0,
	y = 0,
	z = 0
}
const velocity_slow_down = 100
const gravity_add = 300

func get_push(collision, push_dir, velocity):
	if push_dir == push_x:
		if velocity.x > 0:
			return collision.right
		elif velocity.x < 0:
			return collision.left
	elif push_dir == push_y:
		if velocity.y > 0:
			return collision.top
		elif velocity.y < 0:
			return collision.bottom
	elif push_dir == push_z:
		if velocity.z > 0:
			return collision.forward
		elif velocity.z < 0:
			return collision.backward
	return 0

func push(collision, push_dir, velocity):
	if push_dir == push_x:
		if velocity.x > 0:
			player.translation.x -= collision.right
		elif velocity.x < 0:
			player.translation.x += collision.left
	elif push_dir == push_y:
		if velocity.y > 0:
			player.translation.y -= collision.top
		elif velocity.y < 0:
			player.translation.y += collision.bottom
	elif push_dir == push_z:
		if velocity.z > 0:
			player.translation.z -= collision.forward
		elif velocity.z < 0:
			player.translation.z += collision.backward

func unpush(collision, push_dir, velocity):
	if push_dir == push_x:
		if velocity.x > 0:
			player.translation.x += collision.right
		elif velocity.x < 0:
			player.translation.x -= collision.left
	elif push_dir == push_y:
		if velocity.y > 0:
			player.translation.y += collision.top
		elif velocity.y < 0:
			player.translation.y -= collision.bottom
	elif push_dir == push_z:
		if velocity.z > 0:
			player.translation.z += collision.forward
		elif velocity.z < 0:
			player.translation.z -= collision.backward

func will_collide_after_unpush(collision, push_dir, velocity):
	if collision.top != 0 or collision.bottom != 0 or collision.left != 0 \
	or collision.right != 0 or collision.forward != 0 or collision.backward != 0:
		var unpush_position = {
			x = player.translation.x,
			y = player.translation.y,
			z = player.translation.z
		}

		if push_dir == push_x:
			if velocity.x > 0:
				unpush_position.x += collision.right
			elif velocity.x < 0:
				unpush_position.x -= collision.left
		elif push_dir == push_y:
			if velocity.y > 0:
				unpush_position.y += collision.top
			elif velocity.y < 0:
				unpush_position.y -= collision.bottom
		elif push_dir == push_z:
			if velocity.z > 0:
				unpush_position.z += collision.forward
			elif velocity.z < 0:
				unpush_position.z -= collision.backward

		var unpush_collision = get_collision(unpush_position)
		if unpush_collision.top != 0 or unpush_collision.bottom != 0 or unpush_collision.left != 0 \
		or unpush_collision.right != 0 or unpush_collision.forward != 0 or unpush_collision.backward != 0:
			return true
	return false

func get_collision(position):
	var collision = {
		top = 0,
		bottom = 0,
		left = 0,
		right = 0,
		forward = 0,
		backward = 0
	}
	var start_block = {
		x = floor((position.x - player_width / 2) / ChunkLoader.block_size),
		y = floor((position.y - player_height / 2) / ChunkLoader.block_size),
		z = floor((position.z - player_width / 2) / ChunkLoader.block_size)
	}
	var end_block = {
		x = floor((position.x + player_width / 2 - 0.001) / ChunkLoader.block_size),
		y = floor((position.y + player_height / 2 - 0.001) / ChunkLoader.block_size),
		z = floor((position.z + player_width / 2 - 0.001) / ChunkLoader.block_size)
	}

	# for y in range(start_block.y, end_block.y + 1):
	# 	for x in range(start_block.x, end_block.x + 1):
	# 		for z in range(start_block.z, end_block.z + 1):
	# 			if ChunkLoader.has_block(x, y, z):
	# 				var push = (position.y + player_height / 2) - y * ChunkLoader.block_size
	# 				if push > collision.top:
	# 					collision.top = push
					
	# 				push = (y * ChunkLoader.block_size + ChunkLoader.block_size) - (position.y - player_height / 2)
	# 				if push > collision.bottom:
	# 					collision.bottom = push

	# 				push = (x * ChunkLoader.block_size + ChunkLoader.block_size) - (position.x - player_width / 2)
	# 				if push > collision.left:
	# 					collision.left = push

	# 				push = (position.x + player_width / 2) - x * ChunkLoader.block_size
	# 				if push > collision.right:
	# 					collision.right = push

	# 				push = (position.z + player_width / 2) - z * ChunkLoader.block_size
	# 				if push > collision.forward:
	# 					collision.forward = push

	# 				push = (z * ChunkLoader.block_size + ChunkLoader.block_size) - (position.z - player_width / 2)
	# 				if push > collision.backward:
	# 					collision.backward = push

	var min_push_1 = 999999999
	var min_push_2 = 999999999
	var max_column_push_1 = 0
	var max_column_push_2 = 0
	
	for x in range(start_block.x, end_block.x + 1):
		for z in range(start_block.z, end_block.z + 1):
			max_column_push_1 = 0
			max_column_push_2 = 0
			for y in range(start_block.y, end_block.y + 1):
				if ChunkLoader.has_block(x, y, z):
					var push = (position.y + player_height / 2) - y * ChunkLoader.block_size
					if push > max_column_push_1:
						max_column_push_1 = push
					
					push = (y * ChunkLoader.block_size + ChunkLoader.block_size) - (position.y - player_height / 2)
					if push > max_column_push_2:
						max_column_push_2 = push
			if max_column_push_1 < min_push_1 and max_column_push_1 != 0:
				min_push_1 = max_column_push_1
			if max_column_push_2 < min_push_2 and max_column_push_2 != 0:
				min_push_2 = max_column_push_2
	if min_push_1 != 999999999:
		collision.top = min_push_1
	if min_push_2 != 999999999:
		collision.bottom = min_push_2

	min_push_1 = 999999999
	min_push_2 = 999999999
	for y in range(start_block.y, end_block.y + 1):
		for z in range(start_block.z, end_block.z + 1):
			max_column_push_1 = 0
			max_column_push_2 = 0
			for x in range(start_block.x, end_block.x + 1):
				if ChunkLoader.has_block(x, y, z):
					var push = (x * ChunkLoader.block_size + ChunkLoader.block_size) - (position.x - player_width / 2)
					if push > max_column_push_1:
						max_column_push_1 = push

					push = (position.x + player_width / 2) - x * ChunkLoader.block_size
					if push > max_column_push_2:
						max_column_push_2 = push
			if max_column_push_1 < min_push_1 and max_column_push_1 != 0:
				min_push_1 = max_column_push_1
			if max_column_push_2 < min_push_2 and max_column_push_2 != 0:
				min_push_2 = max_column_push_2
	if min_push_1 != 999999999:
		collision.left = min_push_1
	if min_push_2 != 999999999:
		collision.right = min_push_2

	min_push_1 = 999999999
	min_push_2 = 999999999
	for x in range(start_block.x, end_block.x + 1):
		for y in range(start_block.y, end_block.y + 1):
			max_column_push_1 = 0
			max_column_push_2 = 0
			for z in range(start_block.z, end_block.z + 1):
				if ChunkLoader.has_block(x, y, z):
					var push = (position.z + player_width / 2) - z * ChunkLoader.block_size
					if push > max_column_push_1:
						max_column_push_1 = push

					push = (z * ChunkLoader.block_size + ChunkLoader.block_size) - (position.z - player_width / 2)
					if push > max_column_push_2:
						max_column_push_2 = push
			if max_column_push_1 < min_push_1 and max_column_push_1 != 0:
				min_push_1 = max_column_push_1
			if max_column_push_2 < min_push_2 and max_column_push_2 != 0:
				min_push_2 = max_column_push_2
	if min_push_1 != 999999999:
		collision.forward = min_push_1
	if min_push_2 != 999999999:
		collision.backward = min_push_2

	# collision_check_area.translation.x = start_block.x * ChunkLoader.block_size
	# collision_check_area.translation.y = start_block.y * ChunkLoader.block_size
	# collision_check_area.translation.z = start_block.z * ChunkLoader.block_size
	
	if collision.top > max_collision_push:
		collision.top = 0
	if collision.bottom > max_collision_push:
		collision.bottom = 0
	if collision.left > max_collision_push:
		collision.left = 0
	if collision.right > max_collision_push:
		collision.right = 0
	if collision.forward > max_collision_push:
		collision.forward = 0
	if collision.backward > max_collision_push:
		collision.backward = 0

	return collision

func add_velocity(velocity, x, y, z, cap):
	velocity.x += x
	velocity.y += y
	velocity.z += z

	var directional_velocity = sqrt(pow(velocity.x, 2) + pow(velocity.y, 2) + pow(velocity.z, 2))
	if directional_velocity > cap:
		velocity.x = cap / directional_velocity * velocity.x
		velocity.y = cap / directional_velocity * velocity.y
		velocity.z = cap / directional_velocity * velocity.z

func slow_down_velocity(velocity, velocity_slow_down, delta):
	var directional_velocity = sqrt(pow(velocity.x, 2) + pow(velocity.y, 2) + pow(velocity.z, 2))
	var axis_velocity_slow_down = {
		x = 0,
		y = 0,
		z = 0
	}
	if velocity.x != 0:
		axis_velocity_slow_down.x = abs(velocity.x) / directional_velocity * velocity_slow_down
	if velocity.y != 0:
		axis_velocity_slow_down.y = abs(velocity.y) / directional_velocity * velocity_slow_down
	if velocity.z != 0:
		axis_velocity_slow_down.z = abs(velocity.z) / directional_velocity * velocity_slow_down

	if velocity.x > 0:
		if velocity.x - delta * axis_velocity_slow_down.x > 0:
			velocity.x -= delta * axis_velocity_slow_down.x
		else:
			velocity.x = 0
	elif velocity.x < 0:
		if velocity.x + delta * axis_velocity_slow_down.x < 0:
			velocity.x += delta * axis_velocity_slow_down.x
		else:
			velocity.x = 0

	if velocity.y > 0:
		if velocity.y - delta * axis_velocity_slow_down.y > 0:
			velocity.y -= delta * axis_velocity_slow_down.y
		else:
			velocity.y = 0
	elif velocity.y < 0:
		if velocity.y + delta * axis_velocity_slow_down.y < 0:
			velocity.y += delta * axis_velocity_slow_down.y
		else:
			velocity.y = 0

	if velocity.z > 0:
		if velocity.z - delta * axis_velocity_slow_down.z > 0:
			velocity.z -= delta * axis_velocity_slow_down.z
		else:
			velocity.z = 0
	elif velocity.z < 0:
		if velocity.z + delta * axis_velocity_slow_down.z < 0:
			velocity.z += delta * axis_velocity_slow_down.z
		else:
			velocity.z = 0

func player_is_on_the_ground():
	var position = {
		x = player.translation.x,
		y = player.translation.y,
		z = player.translation.z
	}
	position.y -= 0.001

	var collision = get_collision(position)
	if collision.bottom > 0:
		return true
	return false

func move(delta):
	var player_combined_velocity = {
		x = player_velocity.x + player_move_velocity.x,
		y = player_velocity.y + player_move_velocity.y,
		z = player_velocity.z + player_move_velocity.z
	}
	player.translation.x += player_combined_velocity.x * delta
	player.translation.y += player_combined_velocity.y * delta
	player.translation.z += player_combined_velocity.z * delta
	
	var position = {
		x = player.translation.x,
		y = player.translation.y,
		z = player.translation.z
	}
	var collision = get_collision(position)

	var preserve_velocity = {
		x = true,
		y = true,
		z = true
	}
	if get_push(collision, push_y, player_combined_velocity) > 0:
		preserve_velocity.y = false
	if get_push(collision, push_x, player_combined_velocity) > 0:
		preserve_velocity.x = false
	if get_push(collision, push_z, player_combined_velocity) > 0:
		preserve_velocity.z = false

	push(collision, push_x, player_combined_velocity)
	push(collision, push_y, player_combined_velocity)
	push(collision, push_z, player_combined_velocity)

	for i in range(3):
		if Functions.is_max(get_push(collision, push_x, player_combined_velocity), get_push(collision, push_y, player_combined_velocity), get_push(collision, push_z, player_combined_velocity)):
			if not will_collide_after_unpush(collision, push_x, player_combined_velocity):
				unpush(collision, push_x, player_combined_velocity)
				preserve_velocity.x = true
			collision.left = 0
			collision.right = 0
		elif Functions.is_max(get_push(collision, push_y, player_combined_velocity), get_push(collision, push_x, player_combined_velocity), get_push(collision, push_z, player_combined_velocity)):
			if not will_collide_after_unpush(collision, push_y, player_combined_velocity):
				unpush(collision, push_y, player_combined_velocity)
				preserve_velocity.y = true
			collision.top = 0
			collision.bottom = 0
		else:
			if not will_collide_after_unpush(collision, push_z, player_combined_velocity):
				unpush(collision, push_z, player_combined_velocity)
				preserve_velocity.z = true
			collision.forward = 0
			collision.backward = 0
	
	if not preserve_velocity.x:
		player_move_velocity.x = 0
		player_velocity.x = 0
	if not preserve_velocity.y:
		player_move_velocity.y = 0
		player_velocity.y = 0
	if not preserve_velocity.z:
		player_move_velocity.z = 0
		player_velocity.z = 0

	slow_down_velocity(player_move_velocity, move_velocity_slow_down, delta)
	slow_down_velocity(player_velocity, velocity_slow_down, delta)
