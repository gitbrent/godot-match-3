extends Node
class_name Common
# CONST
const GEM_COLOR_NAMES = [Enums.GemColor.RED, Enums.GemColor.ORG, Enums.GemColor.YLW, Enums.GemColor.GRN, Enums.GemColor.BLU, Enums.GemColor.PRP]
const GEM_POINTS:int = 25
# VAR
var highlight_gem1: CommonGemCell = null
var highlight_gem2: CommonGemCell = null

# FILLERS =========================================================

func fill_grid(hbox:HBoxContainer, grid:GridContainer, square0:String, square1:String):
	var size = hbox.get_child_count()
	for i in range(size):
		for j in range(size):
			var brdsq_scene_path = square0
			if (i + j) % 2 == 0:
				brdsq_scene_path = square1
			var brdsq_scene = load(brdsq_scene_path)
			var brdsq = brdsq_scene.instantiate()
			grid.add_child(brdsq)

func fill_hbox(hbox:HBoxContainer, gem_dict:Enums.GemDict, on_cell_click, on_drag_start, on_drag_inprog, on_drag_ended):
	for col_idx in range(hbox.get_child_count()):
		for row_idx in range(8):
			var gem_type = GEM_COLOR_NAMES[randi() % GEM_COLOR_NAMES.size()]
			var gem_cell_scene = load("res://game_boards/all_common/cmn_gem_cell.tscn")
			var gem_cell:CommonGemCell = gem_cell_scene.instantiate()
			hbox.get_child(col_idx).add_child(gem_cell)
			gem_cell.initialize(gem_type, gem_dict)
			var control_node = gem_cell.get_node("GemControl")
			control_node.connect("cell_click", on_cell_click)
			control_node.connect("drag_start", on_drag_start)
			control_node.connect("drag_in_prog", on_drag_inprog)
			control_node.connect("drag_ended", on_drag_ended)

# GEM LOGIC =========================================================

func find_first_possible_swap(hbox:HBoxContainer) -> Array:
	var num_columns: int = hbox.get_child_count()
	var num_rows: int = hbox.get_child(0).get_child_count()
	var board = []

	for x in range(num_columns):
		var column = []
		for y in range(num_rows):
			var gem_cell = hbox.get_child(x).get_child(y)
			column.append(gem_cell)
		board.append(column)

	for x in range(num_columns):
		for y in range(num_rows):
			var gem_cell = board[x][y]
			if gem_cell.is_locked:
				continue

			if x < num_columns - 1 and not board[x + 1][y].is_locked:
				swap(board, x, y, x + 1, y)
				if check_match(board):
					swap(board, x, y, x + 1, y)
					return [gem_cell, board[x + 1][y]]
				swap(board, x, y, x + 1, y)

			if y < num_rows - 1 and not board[x][y + 1].is_locked:
				swap(board, x, y, x, y + 1)
				if check_match(board):
					swap(board, x, y, x, y + 1)
					return [gem_cell, board[x][y + 1]]
				swap(board, x, y, x, y + 1)

	return []

func swap(board, x1, y1, x2, y2):
	var temp = board[x1][y1]
	board[x1][y1] = board[x2][y2]
	board[x2][y2] = temp

func check_match(board) -> bool:
	var num_columns = board.size()
	var num_rows = board[0].size()

	for x in range(num_columns):
		for y in range(num_rows):
			var gem_cell = board[x][y]
			if gem_cell.is_locked:
				continue

			if x < num_columns - 2:
				if not board[x + 1][y].is_locked and not board[x + 2][y].is_locked:
					if gem_cell.gem_color == board[x + 1][y].gem_color and gem_cell.gem_color == board[x + 2][y].gem_color:
						return true

			if y < num_rows - 2:
				if not board[x][y + 1].is_locked and not board[x][y + 2].is_locked:
					if gem_cell.gem_color == board[x][y + 1].gem_color and gem_cell.gem_color == board[x][y + 2].gem_color:
						return true

	return false

func get_matches(hbox: HBoxContainer) -> Array:
	var matches = []
	var num_columns = hbox.get_child_count()
	var num_rows = hbox.get_child(0).get_child_count()

	for row in range(num_rows):
		var last_color = null
		var streak = 0
		var match_start = 0
		for column in range(num_columns):
			var gem_cell = hbox.get_child(column).get_child(row) as CommonGemCell
			if gem_cell.is_locked:
				if streak >= 3:
					var match_cells = []
					for i in range(match_start, column):
						match_cells.append(hbox.get_child(i).get_child(row))
					matches.append({
						"cells": match_cells,
						"count": streak
					})
				streak = 0
				continue

			if gem_cell.gem_color == last_color:
				streak += 1
			else:
				if streak >= 3:
					var match_cells = []
					for i in range(match_start, column):
						match_cells.append(hbox.get_child(i).get_child(row))
					matches.append({
						"cells": match_cells,
						"count": streak
					})
				streak = 1
				match_start = column
				last_color = gem_cell.gem_color

		if streak >= 3:
			var match_cells = []
			for i in range(match_start, num_columns):
				match_cells.append(hbox.get_child(i).get_child(row))
			matches.append({
				"cells": match_cells,
				"count": streak
			})

	for column in range(num_columns):
		var last_color = null
		var streak = 0
		var match_start = 0
		for row in range(num_rows):
			var gem_cell = hbox.get_child(column).get_child(row) as CommonGemCell
			if gem_cell.is_locked:
				if streak >= 3:
					var match_cells = []
					for i in range(match_start, row):
						match_cells.append(hbox.get_child(column).get_child(i))
					matches.append({
						"cells": match_cells,
						"count": streak
					})
				streak = 0
				continue

			if gem_cell.gem_color == last_color:
				streak += 1
			else:
				if streak >= 3:
					var match_cells = []
					for i in range(match_start, row):
						match_cells.append(hbox.get_child(column).get_child(i))
					matches.append({
						"cells": match_cells,
						"count": streak
					})
				streak = 1
				match_start = row
				last_color = gem_cell.gem_color

		if streak >= 3:
			var match_cells = []
			for i in range(match_start, num_rows):
				match_cells.append(hbox.get_child(column).get_child(i))
			matches.append({
				"cells": match_cells,
				"count": streak
			})

	return matches

func has_match_at(x:int, y:int, board:Array) -> bool:
	if board[x][y].is_locked:
		return false
	
	var color = board[x][y].gem_color

	# Check horizontal matches
	var count = 1
	var i = x - 1
	while i >= 0 and not board[i][y].is_locked and board[i][y].gem_color == color:
		count += 1
		i -= 1
	i = x + 1
	while i < board.size() and not board[i][y].is_locked and board[i][y].gem_color == color:
		count += 1
		i += 1
	if count >= 3:
		return true

	# Check vertical matches
	count = 1
	var j = y - 1
	while j >= 0 and not board[x][j].is_locked and board[x][j].gem_color == color:
		count += 1
		j -= 1
	j = y + 1
	while j < board[x].size() and not board[x][j].is_locked and board[x][j].gem_color == color:
		count += 1
		j += 1
	if count >= 3:
		return true

	return false

func check_for_possible_moves(hbox:HBoxContainer) -> bool:
	if find_first_possible_swap(hbox).size() > 0:
		return true
	return false

func highlight_first_swap(hbox:HBoxContainer) -> void:
	var findswap = find_first_possible_swap(hbox)
	if findswap.size() == 2:
		highlight_gem1 = findswap[0]
		highlight_gem2 = findswap[1]
		highlight_gem1.highlight()
		highlight_gem2.highlight()

# UTILS =========================================================

func get_all_matches(hbox:HBoxContainer) -> Array:
	var num_columns: int = hbox.get_child_count()
	var num_rows: int = hbox.get_child(0).get_child_count()
	var matches = []

	for row in range(num_rows):
		var last_color = null
		var streak = 0
		var match_start = 0
		for column in range(num_columns):
			var gem_cell = hbox.get_child(column).get_child(row) as CommonGemCell
			if gem_cell.is_locked:
				if streak >= 3:
					var match_cells = []
					for i in range(match_start, column):
						match_cells.append(hbox.get_child(i).get_child(row))
					matches.append({
						"cells": match_cells,
						"count": streak
					})
				streak = 0
				continue

			if gem_cell.gem_color == last_color:
				streak += 1
			else:
				if streak >= 3:
					var match_cells = []
					for i in range(match_start, column):
						match_cells.append(hbox.get_child(i).get_child(row))
					matches.append({
						"cells": match_cells,
						"count": streak
					})
				streak = 1
				match_start = column
				last_color = gem_cell.gem_color

		if streak >= 3:
			var match_cells = []
			for i in range(match_start, num_columns):
				match_cells.append(hbox.get_child(i).get_child(row))
			matches.append({
				"cells": match_cells,
				"count": streak
			})

	for column in range(num_columns):
		var last_color = null
		var streak = 0
		var match_start = 0
		for row in range(num_rows):
			var gem_cell = hbox.get_child(column).get_child(row) as CommonGemCell
			if gem_cell.is_locked:
				if streak >= 3:
					var match_cells = []
					for i in range(match_start, row):
						match_cells.append(hbox.get_child(column).get_child(i))
					matches.append({
						"cells": match_cells,
						"count": streak
					})
				streak = 0
				continue

			if gem_cell.gem_color == last_color:
				streak += 1
			else:
				if streak >= 3:
					var match_cells = []
					for i in range(match_start, row):
						match_cells.append(hbox.get_child(column).get_child(i))
					matches.append({
						"cells": match_cells,
						"count": streak
					})
				streak = 1
				match_start = row
				last_color = gem_cell.gem_color

		if streak >= 3:
			var match_cells = []
			for i in range(match_start, num_rows):
				match_cells.append(hbox.get_child(column).get_child(i))
			matches.append({
				"cells": match_cells,
				"count": streak
			})

	return matches

func extract_gem_cells_from_matches(matches: Array) -> Array:
	var gem_cells = []
	for match in matches:
		for cell in match.cells:
			if not cell.is_locked:
				gem_cells.append(cell)
	return gem_cells

func find_gem_indices(gem_cell:CommonGemCell) -> Dictionary:
	var parent_vbox = gem_cell.get_parent()
	var hbox = parent_vbox.get_parent()
	
	var vbox_index = -1
	var gem_index = -1
	
	# Get the index of the VBoxContainer in the HBoxContainer
	for i in range(hbox.get_child_count()):
		if hbox.get_child(i) == parent_vbox:
			vbox_index = i
			break
	
	# Get the index of the GemCell in the VBoxContainer
	for j in range(parent_vbox.get_child_count()):
		if parent_vbox.get_child(j) == gem_cell:
			gem_index = j
			break
	
	return {"column": vbox_index, "row": gem_index}

func are_cells_adjacent(gemcell1:CommonGemCell, gemcell2:CommonGemCell) -> bool:
	var cell1 = find_gem_indices(gemcell1)
	var cell2 = find_gem_indices(gemcell2)
	var col1 = cell1.column
	var row1 = cell1.row
	var col2 = cell2.column
	var row2 = cell2.row
	
	# Check if cells are in the same row and adjacent columns
	if row1 == row2 and abs(col1 - col2) == 1:
		return true
	
	# Check if cells are in the same column and adjacent rows
	if col1 == col2 and abs(row1 - row2) == 1:
		return true
	
	# Cells are not adjacent
	return false

func get_gem_at_position(position:Vector2, hbox:HBoxContainer) -> CommonGemCell:
	for vbox in hbox.get_children():
		if vbox is VBoxContainer:
			for gem_cell in vbox.get_children():
				if gem_cell is CommonGemCell and gem_cell.get_global_rect().has_point(position):
					return gem_cell
	return null

func format_gem_indices(indices: Dictionary) -> String:
	return "C%d:R%d" % [indices["column"], indices["row"]]

# =========================================================

func calculate_score_for_matches(matches:Array) -> int:
	var score = 0
	for match in matches:
		var match_length = match["count"]
		# Define scoring logic, e.g., exponential growth for larger matches
		var match_score = match_length * match_length  # Example: score grows quadratically with match length
		score += match_score * GEM_POINTS
	return score

func calculate_scores_for_each_match(matches:Array) -> Dictionary:
	var scores = {}
	for match in matches:
		var count = match["count"]
		var score = count * GEM_POINTS
		for cell in match["cells"]:
			scores[cell] = score
	return scores

# =========================================================

func new_game_explode_replace(hbox:HBoxContainer, colors:Array, delay:float):
	# A:
	for vbox in hbox.get_children():
		for gem_cell in vbox.get_children():
			gem_cell.explode_gem(gem_cell.gem_color, 0)
	# B:
	await delay_time(hbox, delay)
	# C:
	for vbox in hbox.get_children():
		for gem_cell in vbox.get_children():
			gem_cell.replace_gem(colors[randi() % colors.size()], 1)

func delay_time(node:Node, time_sec:float) -> void:
	var tnode = node.get_parent()
	var timer = Timer.new()
	timer.wait_time = time_sec
	timer.one_shot = true
	tnode.add_child(timer)
	timer.start()
	await timer.timeout
	tnode.remove_child(timer)
	timer.queue_free()

# Locked Gems =========================================================

func lock_bottom_two_rows(hbox:HBoxContainer):
	for vbox in hbox.get_children():
		if vbox is VBoxContainer:
			var children = vbox.get_children()
			var num_children = len(children)
			for i in range(num_children - 2, num_children):
				children[i].lock_cell()

func unlock_all_gems(hbox:HBoxContainer):
	for vbox in hbox.get_children():
		if vbox is VBoxContainer:
			for gem_cell in vbox.get_children():
				gem_cell.unlock_cell()

func count_locked_cells(hbox:HBoxContainer) -> int:
	var locked_count = 0
	for vbox in hbox.get_children():
		if vbox is VBoxContainer:
			for gem_cell in vbox.get_children():
				if gem_cell is CommonGemCell and gem_cell.is_locked:
					locked_count += 1
	# Done
	return locked_count

func unlock_adjacent_locked_cells(hbox:HBoxContainer, gem_cell:CommonGemCell):
	var indices = find_gem_indices(gem_cell)
	var x = indices["column"]
	var y = indices["row"]
	
	var adjacent_positions = [
		Vector2(x + 1, y), Vector2(x - 1, y),
		Vector2(x, y + 1), Vector2(x, y - 1)
	]
	
	for pos in adjacent_positions:
		Enums.debug_print("[UALC] Checking adjacent position: ("+ str(pos.x) +", "+ str(pos.y)+ ")", Enums.DEBUG_LEVEL.DEBUG)
		if pos.x >= 0 and pos.y >= 0 and pos.x < hbox.get_child_count() and pos.y < hbox.get_child(0).get_child_count():
			var adjacent_vbox = hbox.get_child(int(pos.x)) as VBoxContainer
			var adjacent_cell = adjacent_vbox.get_child(int(pos.y)) as CommonGemCell
			Enums.debug_print("[UALC] - adjacent cell at ("+ str(pos.x) +", "+ str(pos.y) +") is_locked = "+ str(adjacent_cell.is_locked), Enums.DEBUG_LEVEL.DEBUG)
			if adjacent_cell.is_locked:
				Enums.debug_print("[UALC] - unlocking adjacent locked cell at position: ("+ str(pos.x) +", "+ str(pos.y) +")", Enums.DEBUG_LEVEL.DEBUG)
				adjacent_cell.unlock_cell()
