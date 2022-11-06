extends Node

const top = 1
const bottom = 2
const left = 3
const right = 4
const forward = 5
const backward = 6

const block_size = 8
const chunk_size = 16
const chunk_height = 40
const render_distance = 2

var noise = OpenSimplexNoise.new()

var chunks = {}
var chunk_queue_check = []

func convert_to_block_coordinate(x, y, z):
	return {
		x = floor(x / block_size),
		y = floor(y / block_size),
		z = floor(z / block_size)
	}

func convert_to_chunk_coordinate(block_coordinate):
	return floor(float(block_coordinate) / chunk_size)

func convert_to_remain_block_coordinate(block_coordinate):
	return floor(fposmod(float(block_coordinate), chunk_size))

func add_chunk_to_queue(x, z):
	Multithread.mutex.lock()
	chunk_queue_check.append(to_json({x = x, z = z}))
	Multithread.mutex.unlock()
	var functionref = funcref(self, 'load_chunk')
	if Multithread.threads[0].queue.size() > Multithread.threads[1].queue.size():
		Multithread.add_to_queue(1, functionref, {x = x, z = z})
	else:
		Multithread.add_to_queue(0, functionref, {x = x, z = z})

func chunk_is_in_queue(x, z):
	Multithread.mutex.lock()
	var result = chunk_queue_check.has(to_json({x = x, z = z}))
	Multithread.mutex.unlock()
	return result
	
func load_chunk(chunk_position):
	var x = chunk_position.x
	var z = chunk_position.z
	var blocks = []

	for i in range(chunk_size):
		blocks.append([])
		for j in range(chunk_height):
			blocks[i].append([])
			for k in range(chunk_size):
				blocks[i][j].append({has_block = false})

	for i in range(chunk_size):
		for j in range(chunk_size):
			blocks[i][round((noise.get_noise_2d(x * chunk_size + i, z * chunk_size + j) + 1)/2 * chunk_height)][j].has_block = true



	Multithread.mutex.lock()
	var mesh_instance = MeshInstance.new()
	mesh_instance.translation.x = x * chunk_size * block_size
	mesh_instance.translation.z = z * chunk_size * block_size
	add_child(mesh_instance)

	chunks[to_json({x = x, z = z})] = {
		blocks = blocks,
		mesh_instance = mesh_instance,
		x = x,
		z = z
	}

	chunk_queue_check.erase(to_json({x = x, z = z}))
	Multithread.mutex.unlock()

	reload_chunk_surfaces(x, z)
	if chunk_loaded(x + 1, z):
		reload_chunk_surfaces(x + 1, z)
	if chunk_loaded(x - 1, z):
		reload_chunk_surfaces(x - 1, z)
	if chunk_loaded(x, z + 1):
		reload_chunk_surfaces(x, z + 1)
	if chunk_loaded(x, z - 1):
		reload_chunk_surfaces(x, z - 1)

func unload_chunk(chunk_position):
	var x = chunk_position.x
	var z = chunk_position.z
	var chunk_id = to_json({x = x, z = z})
	chunks[chunk_id].mesh_instance.queue_free()
	chunks[chunk_id].mesh_instance = null
	for block_arr in chunks[chunk_id].blocks:
		block_arr.clear()
	chunks[chunk_id].blocks.clear()
	Multithread.mutex.lock()
	chunks.erase(chunk_id)
	Multithread.mutex.unlock()

func chunk_loaded(x, z):
	return chunks.has(to_json({x = x, z = z}))

func has_block(x, y, z):
	if y < 0 or y >= chunk_height:
		return false
	if chunk_loaded(convert_to_chunk_coordinate(x), convert_to_chunk_coordinate(z)) \
	and chunks[to_json({x = convert_to_chunk_coordinate(x), 
						z = convert_to_chunk_coordinate(z)})].blocks[convert_to_remain_block_coordinate(x)][y][
						convert_to_remain_block_coordinate(z)].has_block:
		return true
	return false

func get_block(x, y, z):
	if y < 0 or y >= chunk_height:
		return -1
	if chunk_loaded(convert_to_chunk_coordinate(x), convert_to_chunk_coordinate(z)):
		return chunks[to_json({x = convert_to_chunk_coordinate(x), 
								z = convert_to_chunk_coordinate(z)})].blocks[convert_to_remain_block_coordinate(x)][y][
								convert_to_remain_block_coordinate(z)]
	return -1

func reload_chunk_surfaces(x, z):
	var chunk_id = to_json({x = x, z = z})

	var blocks_array = [-1, -1, -1, -1, -1, -1, -1]
	blocks_array[0] = chunks[chunk_id].blocks
	if chunk_loaded(x - 1, z):
		blocks_array[left] = chunks[to_json({x = x - 1, z = z})].blocks
	if chunk_loaded(x + 1, z):
		blocks_array[right] = chunks[to_json({x = x + 1, z = z})].blocks
	if chunk_loaded(x, z + 1):
		blocks_array[forward] = chunks[to_json({x = x, z = z + 1})].blocks
	if chunk_loaded(x, z - 1):
		blocks_array[backward] = chunks[to_json({x = x, z = z - 1})].blocks

	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in range(chunk_size):
		for j in range(chunk_height):
			for k in range(chunk_size):
				if chunks[chunk_id].blocks[i][j][k].has_block:
					add_block(surface_tool, blocks_array, i, j, k)

	surface_tool.generate_normals()
	var mesh = surface_tool.commit()

	chunks[chunk_id].mesh_instance.set_mesh(mesh)

func add_block_surface(surface_tool, x, y, z, dir):
	x *= block_size
	y *= block_size
	z *= block_size

	if dir == top:
		surface_tool.add_vertex(Vector3(x             , y + block_size, z             ))
		surface_tool.add_vertex(Vector3(x + block_size, y + block_size, z             ))
		surface_tool.add_vertex(Vector3(x             , y + block_size, z + block_size))

		surface_tool.add_vertex(Vector3(x + block_size, y + block_size, z + block_size))
		surface_tool.add_vertex(Vector3(x             , y + block_size, z + block_size))
		surface_tool.add_vertex(Vector3(x + block_size, y + block_size, z             ))

	elif dir == bottom:
		surface_tool.add_vertex(Vector3(x             , y             , z             ))
		surface_tool.add_vertex(Vector3(x             , y             , z + block_size))
		surface_tool.add_vertex(Vector3(x + block_size, y             , z             ))

		surface_tool.add_vertex(Vector3(x + block_size, y             , z + block_size))
		surface_tool.add_vertex(Vector3(x + block_size, y             , z             ))
		surface_tool.add_vertex(Vector3(x             , y             , z + block_size))

	elif dir == left:
		surface_tool.add_vertex(Vector3(x             , y             , z             ))
		surface_tool.add_vertex(Vector3(x             , y + block_size, z + block_size))
		surface_tool.add_vertex(Vector3(x             , y             , z + block_size))

		surface_tool.add_vertex(Vector3(x             , y             , z             ))
		surface_tool.add_vertex(Vector3(x             , y + block_size, z             ))
		surface_tool.add_vertex(Vector3(x             , y + block_size, z + block_size))

	elif dir == right:
		surface_tool.add_vertex(Vector3(x + block_size, y             , z             ))
		surface_tool.add_vertex(Vector3(x + block_size, y             , z + block_size))
		surface_tool.add_vertex(Vector3(x + block_size, y + block_size, z + block_size))

		surface_tool.add_vertex(Vector3(x + block_size, y             , z             ))
		surface_tool.add_vertex(Vector3(x + block_size, y + block_size, z + block_size))
		surface_tool.add_vertex(Vector3(x + block_size, y + block_size, z             ))

	elif dir == forward:
		surface_tool.add_vertex(Vector3(x             , y + block_size, z + block_size))
		surface_tool.add_vertex(Vector3(x + block_size, y + block_size, z + block_size))
		surface_tool.add_vertex(Vector3(x + block_size, y             , z + block_size))

		surface_tool.add_vertex(Vector3(x             , y + block_size, z + block_size))
		surface_tool.add_vertex(Vector3(x + block_size, y             , z + block_size))
		surface_tool.add_vertex(Vector3(x             , y             , z + block_size))

	elif dir == backward:
		surface_tool.add_vertex(Vector3(x             , y + block_size, z             ))
		surface_tool.add_vertex(Vector3(x + block_size, y             , z             ))
		surface_tool.add_vertex(Vector3(x + block_size, y + block_size, z             ))

		surface_tool.add_vertex(Vector3(x             , y + block_size, z             ))
		surface_tool.add_vertex(Vector3(x             , y             , z             ))
		surface_tool.add_vertex(Vector3(x + block_size, y             , z             ))

func add_block(surface_tool, blocks_array, x, y, z):
	if y + 1 < chunk_height and not blocks_array[0][x][y + 1][z].has_block:
		add_block_surface(surface_tool, x, y, z, top)
	if y - 1 >= 0 and not blocks_array[0][x][y - 1][z].has_block:
		add_block_surface(surface_tool, x, y, z, bottom)
	if x - 1 >= 0 and not blocks_array[0][x - 1][y][z].has_block:
		add_block_surface(surface_tool, x, y, z, left)
	if x + 1 < chunk_size and not blocks_array[0][x + 1][y][z].has_block:
		add_block_surface(surface_tool, x, y, z, right)
	if z + 1 < chunk_size and not blocks_array[0][x][y][z + 1].has_block:
		add_block_surface(surface_tool, x, y, z, forward)
	if z - 1 >= 0 and not blocks_array[0][x][y][z - 1].has_block:
		add_block_surface(surface_tool, x, y, z, backward)

	if x == 0 and not blocks_array[left] is int:
		if not blocks_array[left][chunk_size - 1][y][z].has_block:
			add_block_surface(surface_tool, x, y, z, left)
	if x == chunk_size - 1 and not blocks_array[right] is int:
		if not blocks_array[right][0][y][z].has_block:
			add_block_surface(surface_tool, x, y, z, right)
	if z == chunk_size - 1 and not blocks_array[forward] is int:
		if not blocks_array[forward][x][y][0].has_block:
			add_block_surface(surface_tool, x, y, z, forward)
	if z == 0 and not blocks_array[backward] is int:
		if not blocks_array[backward][x][y][chunk_size - 1].has_block:
			add_block_surface(surface_tool, x, y, z, backward)

func load_chunks_around_player(player_chunk_position):
	var i = 0
	var j = 0
	var up = 1
	var down = 2
	var left = 3
	var right = 4
	var dir = up
	var distance = 0
	while distance <= render_distance:
		Multithread.mutex.lock()
		if not chunk_loaded(player_chunk_position.x + i, player_chunk_position.z + j) \
		and not chunk_is_in_queue(player_chunk_position.x + i, player_chunk_position.z + j):
			add_chunk_to_queue(player_chunk_position.x + i, player_chunk_position.z + j)
		Multithread.mutex.unlock()
		
		if dir == up:
			j -= 1
			if j == - (distance + 1):
				distance += 1
				dir = right
			
		elif dir == right:
			i += 1
			if i == distance:
				dir = down

		elif dir == down:
			j += 1
			if j == distance:
				dir = left

		elif dir == left:
			i -= 1
			if i == -distance:
				dir = up

func unload_chunk_far_from_player(player_chunk_position):
	Multithread.mutex.lock()
	for chunk in chunks.values():
		if abs(chunk.x - player_chunk_position.x) > render_distance or abs(chunk.z - player_chunk_position.z) > render_distance:
			var functionref = funcref(self, 'unload_chunk')
			Multithread.add_to_queue(2, functionref, {x = chunk.x, z = chunk.z})
	Multithread.mutex.unlock()

func _ready():
	randomize()
	noise.seed = randi()
	noise.octaves = 3
	noise.period = 89
	noise.persistence = 0.256

	Multithread.add_new_thread()
	Multithread.add_new_thread()
	Multithread.add_new_thread()