extends Node

const top = 1
const bottom = 2
const left = 3
const right = 4
const forward = 5
const backward = 6

func get_targeted_block(pos, dir, distance):
	var targeted_block = {
		found = false,
		block = {
			x = 0,
			y = 0,
			z = 0
		},
		previous_block = {
			x = 0,
			y = 0,
			z = 0
		},
		face = 0
	}
	var previous_block = ChunkLoader.convert_to_block_coordinate(pos.x, pos.y, pos.z)

	var current_pos = {
		x = pos.x,
		y = pos.y,
		z = pos.z
	}
	var dir_sign = {
		x = 0,
		y = 0,
		z = 0
	}
	if dir.x > 0:
		dir_sign.x = 1
	elif dir.x < 0:
		dir_sign.x = -1	
	if dir.y > 0:
		dir_sign.y = 1
	elif dir.y < 0:
		dir_sign.y = -1	
	if dir.z > 0:
		dir_sign.z = 1
	elif dir.z < 0:
		dir_sign.z = -1	

	var count = 0
	while Functions.distance(pos, current_pos) <= distance:
		count += 1
		var distance_to_next_block = {
			x = -1,
			y = -1,
			z = -1
		}
		if dir.x > 0:
			distance_to_next_block.x = ceil(current_pos.x / ChunkLoader.block_size) * ChunkLoader.block_size - current_pos.x + 0.001
		elif dir.x < 0:
			distance_to_next_block.x = current_pos.x - floor(current_pos.x / ChunkLoader.block_size) * ChunkLoader.block_size + 0.001
		if dir.y > 0:
			distance_to_next_block.y = ceil(current_pos.y / ChunkLoader.block_size) * ChunkLoader.block_size - current_pos.y + 0.001
		elif dir.y < 0:
			distance_to_next_block.y = current_pos.y - floor(current_pos.y / ChunkLoader.block_size) * ChunkLoader.block_size + 0.001
		if dir.z > 0:
			distance_to_next_block.z = ceil(current_pos.z / ChunkLoader.block_size) * ChunkLoader.block_size - current_pos.z + 0.001
		elif dir.z < 0:
			distance_to_next_block.z = current_pos.z - floor(current_pos.z / ChunkLoader.block_size) * ChunkLoader.block_size + 0.001

		var distance_div_dir = {
			x = 0,
			y = 0,
			z = 0
		}
		if dir.x != 0:
			distance_div_dir.x = abs(distance_to_next_block.x / dir.x)
		if dir.y != 0:
			distance_div_dir.y = abs(distance_to_next_block.y / dir.y)
		if dir.z != 0:
			distance_div_dir.z = abs(distance_to_next_block.z / dir.z)

		if Functions.is_min(distance_div_dir.x, distance_div_dir.y, distance_div_dir.z):
			current_pos.x += distance_to_next_block.x * dir_sign.x
			if dir.x != 0:
				current_pos.y += distance_to_next_block.x / abs(dir.x) * abs(dir.y) * dir_sign.y
				current_pos.z += distance_to_next_block.x / abs(dir.x) * abs(dir.z) * dir_sign.z
		elif Functions.is_min(distance_div_dir.y, distance_div_dir.x, distance_div_dir.z):
			current_pos.y += distance_to_next_block.y * dir_sign.y
			if dir.y != 0:
				current_pos.x += distance_to_next_block.y / abs(dir.y) * abs(dir.x) * dir_sign.x
				current_pos.z += distance_to_next_block.y / abs(dir.y) * abs(dir.z) * dir_sign.z
		else:
			current_pos.z += distance_to_next_block.z * dir_sign.z
			if dir.z != 0:
				current_pos.x += distance_to_next_block.z / abs(dir.z) * abs(dir.x) * dir_sign.x
				current_pos.y += distance_to_next_block.z / abs(dir.z) * abs(dir.y) * dir_sign.y
		
		var current_block = ChunkLoader.convert_to_block_coordinate(current_pos.x, current_pos.y, current_pos.z)
		if ChunkLoader.has_block(current_block.x, current_block.y, current_block.z):
			targeted_block.found = true
			targeted_block.block = current_block
			targeted_block.previous_block = previous_block
			if previous_block.x > current_block.x:
				targeted_block.face = right
			elif previous_block.x < current_block.x:
				targeted_block.face = left
			elif previous_block.y > current_block.y:
				targeted_block.face = top
			elif previous_block.y < current_block.y:
				targeted_block.face = bottom
			elif previous_block.z > current_block.z:
				targeted_block.face = forward
			elif previous_block.z < current_block.z:
				targeted_block.face = backward
			break
		
		previous_block = ChunkLoader.convert_to_block_coordinate(current_pos.x, current_pos.y, current_pos.z)
	return targeted_block
