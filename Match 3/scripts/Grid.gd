extends Node2D

# State Machine
enum {wait, move}
var state

# Grid variables
export (int) var width
export (int) var height
export (Vector2) var start
export (int) var offset
export (int) var y_offset

# obstacle
export (PoolVector2Array) var empty_spaces
export (PoolVector2Array) var ice_spaces
export (PoolVector2Array) var lock_spaces
export (PoolVector2Array) var concrete_spaces
export (PoolVector2Array) var slime_spaces
var damaged_slime = false

signal make_ice
signal damage_ice
signal make_lock
signal damage_lock
signal make_concrete
signal damage_concrete
signal make_slime
signal damage_slime

var possible_pieces = [
	preload("res://scenes/BluePiece.tscn").instance(),
#	preload("res://scenes/GreenPiece.tscn").instance(),
#	preload("res://scenes/LightGreenPiece.tscn").instance(),
	preload("res://scenes/OrangePiece.tscn").instance(),
	preload("res://scenes/PinkPiece.tscn").instance(),
#	preload("res://scenes/YellowPiece.tscn").instance()
]
# current pieces in the scene
var all_pieces = []
var current_matches = []

# swap back variables
var piece_one = null
var piece_two = null
var last_place = Vector2.ZERO
var last_direction = Vector2.ZERO
var move_checked = false

# touch variables
var first_touch = Vector2.ZERO
var final_touch = Vector2.ZERO
var grid_position = Vector2.ZERO # Touch position
var swiping = false

# scoring variables
signal update_score
signal setup_max_score
export (int) var max_score
export (int) var piece_value
var streak = 1

# counter variables
signal update_counter
export (int) var current_counter_value
export(bool) var is_moves
signal game_over

# goal variables
signal check_goal

# color bomb variables
var color_bomb_used = false

# collectibles/sinker
export (PackedScene) var sinker_piece
export (bool) var sinkers_in_scene
export (int) var max_sinkers
var current_sinkers = 0

# effects
var particle_effect = preload("res://scenes/ParticleEffect.tscn")
var animated_effect = preload("res://scenes/AnimatedExplosion.tscn")

func _ready():
	state = move
	# change random seed
	randomize()
	all_pieces = make_2d_array()
	if sinkers_in_scene:
		spawn_sinkers(max_sinkers)
	spawn_pieces()
	spawn_ice()
	spawn_lock()
	spawn_concrete()
	spawn_slime()
	emit_signal("update_counter", current_counter_value)
	emit_signal("setup_max_score", max_score)
	if !is_moves:
		$Timer.start()

func restricted_fill(column, row):
	# check the empty pieces
	return is_in_array(empty_spaces, Vector2(column, row)) \
		|| is_in_array(concrete_spaces, Vector2(column, row)) \
		|| is_in_array(slime_spaces, Vector2(column, row))

func restricted_move(place):
	# checks the licorice pieces
	return is_in_array(lock_spaces, place)

func is_in_array(array, item):
	for i in array.size():
		if array[i] == item:
			return true
	return false

func remove_from_array(array, item):
	# iterate backwards	
	for i in range(array.size() - 1, -1, -1):
		if array[i] == item:
			array.remove(i)
	return array

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

func spawn_pieces():
	for i in width:
		for j in height:
			if !restricted_fill(i, j) and all_pieces[i][j] == null:
				spawn_piece(i, j)

func spawn_piece(i, j):
	# choose a random number and store it
	var rand = floor(rand_range(0, possible_pieces.size()))
	# checks for possible matches and replaces piece
	var loops = 0
	while (match_at(i, j, possible_pieces[rand].color) && loops < 100):
		rand = floor(rand_range(0, possible_pieces.size()))
		loops += 1
	# instance that piece from the array
	var piece = possible_pieces[rand].duplicate()
	add_child(piece)
	piece.position = grid_to_pixel(i, j - y_offset)
	piece.move(grid_to_pixel(i, j))
	all_pieces[i][j] = piece

func spawn_ice():
	for i in ice_spaces.size():
		emit_signal("make_ice", ice_spaces[i])

func spawn_lock():
	for i in lock_spaces.size():
		emit_signal("make_lock", lock_spaces[i])

func spawn_concrete():
	for i in concrete_spaces.size():
		emit_signal("make_concrete", concrete_spaces[i])

func spawn_slime():
	for i in slime_spaces.size():
		emit_signal("make_slime", slime_spaces[i])

func spawn_sinkers(amount):
	for i in amount:
		var column = floor(rand_range(0, width))
		while all_pieces[column][height - 1] != null or restricted_fill(column, height - 1):
			column = floor(rand_range(0, width))
		var current = sinker_piece.instance()
		add_child(current)
		current.position = grid_to_pixel(column, height - 1)
		all_pieces[column][height - 1] = current
		current_sinkers += 1

func is_piece_sinker(column, row):
	return all_pieces[column][row] != null and all_pieces[column][row].color == "None"

func match_at(i, j, color):
	# checks to the left
	if i > 1:
		if all_pieces[i - 1][j] != null && all_pieces[i - 2][j] != null:
			if all_pieces[i - 1][j].color == color && all_pieces[i - 2][j].color == color:
				return true
	# checks down
	if j > 1:
		if all_pieces[i][j - 1] != null && all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].color == color && all_pieces[i][j - 2].color == color:
				return true

func grid_to_pixel(column, row):
	# returns scene coordinates based on column and row
	var new_x = start.x + offset * column
	var new_y = start.y + -offset * row
	return Vector2(new_x, new_y)

func pixel_to_grid(pixel_position: Vector2) -> Vector2:
	# returns position in grid from scene coordinates
	var new_x = round((pixel_position.x - start.x) / offset)
	var new_y = round((pixel_position.y - start.y) / -offset)
	return Vector2(new_x, new_y)

func is_in_grid(pos: Vector2) -> bool:
	if pos.x >= 0 && pos.x < width:
		if pos.y >= 0 && pos.y < height:
			return true
	return false

func _input(event):
	if state == move:
		if Input.is_action_just_pressed("ui_touch") && not swiping:
			first_touch = get_global_mouse_position()
			grid_position = pixel_to_grid(first_touch)
			if is_in_grid(grid_position):
				swiping = true
		if Input.is_action_just_released("ui_touch"):
			if swiping:
				final_touch = get_global_mouse_position()
				var new_grid_position = pixel_to_grid(final_touch)
				if is_in_grid(new_grid_position):
					if legal_movement_check(grid_position, new_grid_position):
						swap_pieces(grid_position, new_grid_position)
				swiping = false

func swap_pieces(grid_position, new_grid_position):
	# Swaps position between two pieces
	var first_piece = all_pieces[grid_position.x][grid_position.y]
	var other_piece = all_pieces[new_grid_position.x][new_grid_position.y]
	if first_piece != null && other_piece != null:
		if !restricted_move(grid_position) and !restricted_move(new_grid_position):
			if first_piece.color == "color" and other_piece.color == "color":
				clear_board()
			if is_color_bomb(first_piece, other_piece):
				# FIXME
				if is_piece_sinker(grid_position.x, grid_position.y) or is_piece_sinker(new_grid_position.x, new_grid_position.y):
					swap_back()
					return
				if first_piece.color == "color":
					match_color(other_piece.color)
					match_and_dim(first_piece)
					add_to_array(grid_position)
				else:
					match_color(first_piece.color)
					match_and_dim(other_piece)
					add_to_array(new_grid_position)
			last_place = grid_position
			last_direction = new_grid_position
			piece_one = first_piece
			piece_two = other_piece
			state = wait
			all_pieces[new_grid_position.x][new_grid_position.y] = first_piece
			all_pieces[grid_position.x][grid_position.y] = other_piece
			first_piece.move(grid_to_pixel(new_grid_position.x, new_grid_position.y))
			other_piece.move(grid_to_pixel(grid_position.x, grid_position.y))
			if !move_checked:
				find_matches()

func is_color_bomb(piece_one, piece_two):
	if piece_one.color == "color" or piece_two.color == "color":
		color_bomb_used = true
		return true
	return false

func swap_back():
	# Move the previously swapped pieces back to the previous place
	if piece_one != null && piece_two != null:
		swap_pieces(last_place, last_direction)
	state = move
	move_checked = false
	
func legal_movement_check(grid1, grid2):
	# Movement is legal only if absolute sum of x and y is exactly 1
	# abs difference is 2 if movement is diagonal, 0 if no movement at all, 2< if completely out of range
	var difference = grid1 - grid2
	if abs(difference.x) + abs(difference.y) == 1:
		return true
	else:
		return false

func find_matches():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and !is_piece_sinker(i, j):
				var current_color = all_pieces[i][j].color
				if i > 0 && i < width - 1:
					if all_pieces[i - 1][j] != null && all_pieces[i + 1][j] != null:
						if all_pieces[i - 1][j].color == current_color && all_pieces[i + 1][j].color == current_color:
							match_and_dim(all_pieces[i - 1][j])
							match_and_dim(all_pieces[i][j])
							match_and_dim(all_pieces[i + 1][j])
							add_to_array(Vector2(i, j))
							add_to_array(Vector2(i + 1, j))
							add_to_array(Vector2(i - 1, j))
				if j > 0 && j < height - 1:
					if all_pieces[i][j - 1] != null && all_pieces[i][j + 1] != null:
						if all_pieces[i][j - 1].color == current_color && all_pieces[i][j + 1].color == current_color:
							match_and_dim(all_pieces[i][j - 1])
							match_and_dim(all_pieces[i][j])
							match_and_dim(all_pieces[i][j + 1])
							add_to_array(Vector2(i, j))
							add_to_array(Vector2(i, j + 1))
							add_to_array(Vector2(i, j - 1))
	get_bombed_pieces()
	get_parent().get_node("DestroyTimer").start()

func get_bombed_pieces():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched:
					if all_pieces[i][j].is_column_bomb:
						match_all_in_column(i)
					elif all_pieces[i][j].is_row_bomb:
						match_all_in_row(j)
					elif all_pieces[i][j].is_adjacent_bomb:
						find_adjacent_pieces(i, j)
					
func add_to_array(value, array = current_matches):
	if !array.has(value):
		array.append(value)

func match_and_dim(item):
	item.matched = true
	item.dim()

func find_bombs():
	if !color_bomb_used:
		for i in current_matches.size():
			var current_column = current_matches[i].x
			var current_row = current_matches[i].y
			var current_color = all_pieces[current_column][current_row].color
			var col_matched = 0
			var row_matched = 0
			for j in current_matches.size():
				var this_column = current_matches[j].x
				var this_row = current_matches[j].y
				var this_color = all_pieces[this_column][this_row].color
				if this_column == current_column and current_color == this_color:
					col_matched += 1
				if this_row == current_row and current_color == this_color:
					row_matched += 1
			# 0 is an adj bomb, 1 is a row bomb, and 2 is a column bomb
			# 3 is a color bomb
			if col_matched == 5 or row_matched == 5:
				make_bomb(3, current_color)
				continue
			elif col_matched >= 3 and row_matched >= 3:
				make_bomb(0, current_color)
				continue
			elif col_matched == 4:
				make_bomb(1, current_color)
				continue
			elif row_matched == 4:
				make_bomb(2, current_color)
				continue

func make_bomb(bomb_type, color):
	for i in current_matches.size():
		var current_column = current_matches[i].x
		var current_row = current_matches[i].y
		if all_pieces[current_column][current_row] == piece_one and piece_one.color == color:
			# Make piece_one a bomb
			damage_special(current_column, current_row)
			piece_one.matched = false
			change_bomb(bomb_type, piece_one)
		if all_pieces[current_column][current_row] == piece_two and piece_two.color == color:
			# Make piece_two a bomb
			damage_special(current_column, current_row)
			piece_two.matched = false
			change_bomb(bomb_type, piece_two)

func change_bomb(bomb_type, piece):
	if bomb_type == 0:
		piece.make_adjacent_bomb()
	elif bomb_type == 1:
		piece.make_row_bomb()
	elif bomb_type == 2:
		piece.make_column_bomb()
	elif bomb_type == 3:
		piece.make_color_bomb()

func destroy_matched():
	find_bombs()
	var was_matched = false
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched:
					emit_signal("check_goal", all_pieces[i][j].color)
					damage_special(i, j)
					was_matched = true
					all_pieces[i][j].queue_free()
					all_pieces[i][j] = null
					make_effect(particle_effect, i, j)
					make_effect(animated_effect, i, j)
					emit_signal("update_score", piece_value * streak)
	move_checked = true
	if was_matched:
		get_parent().get_node("CollapseTimer").start()
	else:
		swap_back()
	current_matches.clear()

func make_effect(effect, column, row):
	var current = effect.instance()
	current.position = grid_to_pixel(column, row)
	add_child(current)

func check_concrete(column, row):
	# check right
	if column < width - 1:
		emit_signal("damage_concrete", Vector2(column + 1, row))
	# check left
	if column > 0:
		emit_signal("damage_concrete", Vector2(column - 1, row))
	# check up
	if row > height - 1:
		emit_signal("damage_concrete", Vector2(column, row + 1))
	if row > 0:
		emit_signal("damage_concrete", Vector2(column, row - 1))

func check_slime(column, row):
	# check right
	if column < width - 1:
		emit_signal("damage_slime", Vector2(column + 1, row))
	# check left
	if column > 0:
		emit_signal("damage_slime", Vector2(column - 1, row))
	# check up
	if row < height - 1:
		emit_signal("damage_slime", Vector2(column, row + 1))
	if row > 0:
		emit_signal("damage_slime", Vector2(column, row - 1))

func damage_special(column, row):
	emit_signal("damage_ice", Vector2(column, row))
	emit_signal("damage_lock", Vector2(column, row))
	check_concrete(column, row)
	check_slime(column, row)

func match_color(color):
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and !is_piece_sinker(i, j):
				if all_pieces[i][j].color == color:
					match_and_dim(all_pieces[i][j])
					add_to_array(Vector2(i, j))

func clear_board():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and !is_piece_sinker(i, j):
				match_and_dim(all_pieces[i][j])
				add_to_array(Vector2(i, j))

func _on_DestroyTimer_timeout():
	destroy_matched()

func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null && !restricted_fill(i, j):
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	destroy_sinkers()
	get_parent().get_node("RefillTimer").start()

func _on_CollapseTimer_timeout():
	collapse_columns()

func refill_columns():
	if current_sinkers < max_sinkers:
		spawn_sinkers(max_sinkers - current_sinkers)
	streak += 1
	for i in width:
		for j in height:
			if all_pieces[i][j] == null && !restricted_fill(i, j):
				spawn_piece(i, j)
	after_refill()

func after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if match_at(i, j, all_pieces[i][j].color) or all_pieces[i][j].matched:
					find_matches()
					get_parent().get_node("DestroyTimer").start()
					return
	if !damaged_slime:
		generate_slime()
	state = move
	streak = 1
	move_checked = false
	damaged_slime = false
	color_bomb_used = false
	if is_moves:
		current_counter_value -= 1
		emit_signal("update_counter")
		if current_counter_value == 0:
			declare_game_over()
	
func generate_slime():
	# make sure there are slime pieces on the board
	if slime_spaces.size() > 0:
		var slime_made = false
		var tracker = 0
		while !slime_made and tracker < 100:
			# check a random slime
			var random_num = floor(rand_range(0, slime_spaces.size()))
			var curr_x = slime_spaces[random_num].x
			var curr_y = slime_spaces[random_num].y
			var neighbor = find_normal_neighbor(curr_x, curr_y)
			if neighbor != null:
				# turn that neighboar into a slime
				# remove the piece
				all_pieces[neighbor.x][neighbor.y].queue_free()
				all_pieces[neighbor.x][neighbor.y] = null
				# add the new spot to the array of slimes
				slime_spaces.append(Vector2(neighbor.x, neighbor.y))
				# send signal to slime holder to make new slime
				emit_signal("make_slime", Vector2(neighbor.x, neighbor.y))
				slime_made = true
			tracker += 1

func find_normal_neighbor(column, row):
	# check right first
	if is_in_grid(Vector2(column + 1, row)):
		if all_pieces[column + 1][row] != null and !is_piece_sinker(column + 1, row):
			return Vector2(column + 1, row)
	# check left
	if is_in_grid(Vector2(column - 1, row)):
		if all_pieces[column - 1][row] != null and !is_piece_sinker(column - 1, row):
			return Vector2(column - 1, row)
	# check up
	if is_in_grid(Vector2(column, row + 1)):
		if all_pieces[column][row + 1] != null and !is_piece_sinker(column, row + 1):
			return Vector2(column, row + 1)
	# check down
	if is_in_grid(Vector2(column, row - 1)):
		if all_pieces[column][row - 1] != null and !is_piece_sinker(column, row - 1):
			return Vector2(column, row - 1)
	return null

func match_all_in_column(column):
	for i in height:
		if all_pieces[column][i] != null and !is_piece_sinker(column, i):
			if all_pieces[column][i].is_row_bomb:
				match_all_in_row(i)
			if all_pieces[column][i].is_adjacent_bomb:
				find_adjacent_pieces(column, i)
			all_pieces[column][i].matched = true

func match_all_in_row(row):
	for i in width:
		if all_pieces[i][row] != null and !is_piece_sinker(i, row):
			if  all_pieces[i][row].is_column_bomb:
				match_all_in_column(i)
			if  all_pieces[i][row].is_adjacent_bomb:
				find_adjacent_pieces(i, row)
			all_pieces[i][row].matched = true

func find_adjacent_pieces(column, row):
	for i in range(-1, 2):
		for j in range(-1, 2):
			if is_in_grid(Vector2(column + i, row + j)):
				if all_pieces[column + i][row + j] != null and !is_piece_sinker(column + i, row + j):
					if all_pieces[column][i].is_row_bomb:
						match_all_in_row(i)
					if all_pieces[i][row].is_column_bomb:
						match_all_in_column(i)
					all_pieces[column + i][row + j].matched = true

func destroy_sinkers():
	for i in width:
		if all_pieces[i][0] != null:
			if all_pieces[i][0].color == "None":
				all_pieces[i][0].matched = true
				current_sinkers -= 1

func _on_RefillTimer_timeout():
	refill_columns()

func _on_LockHolder_remove_lock(place):
	lock_spaces = remove_from_array(lock_spaces, place)

func _on_ConcreteHolder_remove_concrete(place):
	concrete_spaces = remove_from_array(concrete_spaces, place)

func _on_SlimeHolder_remove_slime(place):
	damaged_slime = true
	slime_spaces = remove_from_array(slime_spaces, place)

func _on_Timer_timeout():
	current_counter_value -= 1
	emit_signal("update_counter")
	if current_counter_value == 0:
		declare_game_over()
		$Timer.stop()

func declare_game_over():
	emit_signal("game_over")
	state = wait
