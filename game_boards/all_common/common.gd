extends Node
class_name Common
#
const GEM_COLOR_NAMES = [Enums.GemColor.RED, Enums.GemColor.ORG, Enums.GemColor.YLW, Enums.GemColor.GRN, Enums.GemColor.BLU, Enums.GemColor.PRP]
const GEM_POINTS:int = 25
#
var highlight_gem1: CommonGemCell = null
var highlight_gem2: CommonGemCell = null

# =========================================================

func fill_grid(hbox:HBoxContainer, grid:GridContainer, square0:String, square1:String):
	var size = hbox.get_child_count()
	for i in range(size):
		for j in range(size):
			# Load the appropriate scene based on the checkerboard pattern
			var brdsq_scene_path = square0  # Light square
			if (i + j) % 2 == 0:
				brdsq_scene_path = square1  # Dark square
			
			# Load and instantiate the scene
			var brdsq_scene = load(brdsq_scene_path)
			var brdsq = brdsq_scene.instantiate()
			
			# Add the instantiated square to the grid container
			grid.add_child(brdsq)

func fill_hbox(hbox:HBoxContainer, gem_dict:Enums.GemDict, on_cell_click):
	for col_idx in range(hbox.get_child_count()):
		for row_idx in range(8):
			# A: random gem
			var gem_type = GEM_COLOR_NAMES[randi() % GEM_COLOR_NAMES.size()]
			# B: create/add
			var gem_cell_scene = load("res://game_boards/all_common/cmn_gem_cell.tscn")
			var gem_cell:CommonGemCell = gem_cell_scene.instantiate()
			hbox.get_child(col_idx).add_child(gem_cell)
			gem_cell.initialize(gem_type, gem_dict)
			var control_node = gem_cell.get_node("GemControl")
			control_node.connect("cell_click", on_cell_click)
			#control_node.connect("drag_start", self._on_cell_click) # TODO:
			#control_node.connect("drag_ended", self._on_cell_click) # TODO:

# =========================================================

# NEW

func find_first_possible_swap(hbox:HBoxContainer) -> Array:
	var num_columns: int = hbox.get_child_count()
	var num_rows: int = hbox.get_child(0).get_child_count()
	# Create a 2D array to represent the board
	var board = []
	for x in range(num_columns):
		var column = []
		for y in range(num_rows):
			column.append(hbox.get_child(x).get_child(y))
		board.append(column)
	# Try swapping each gem with its neighbors and check for matches
	var swaps = [[0, 1], [1, 0]]  # Only right and down to avoid duplicate checks
	for x in range(num_columns):
		for y in range(num_rows):
			for swap in swaps:
				var dx = swap[0]
				var dy = swap[1]
				var nx = x + dx
				var ny = y + dy
				if nx < num_columns and ny < num_rows:
					# Swap using a temporary variable
					var temp = board[x][y]
					board[x][y] = board[nx][ny]
					board[nx][ny] = temp
					# Check for a match
					if has_match_at(x, y, board) or has_match_at(nx, ny, board):
						# Swap back
						temp = board[x][y]
						board[x][y] = board[nx][ny]
						board[nx][ny] = temp
						# Return the coordinates of the first valid swap
						return [board[x][y], board[nx][ny]]
					# Swap back
					temp = board[x][y]
					board[x][y] = board[nx][ny]
					board[nx][ny] = temp
	return []  # No moves possible

func highlight_first_swap(hbox:HBoxContainer) -> void:
	var swap = find_first_possible_swap(hbox)
	if swap.size() == 2:
		highlight_gem1 = swap[0]
		highlight_gem2 = swap[1]
		highlight_gem1.highlight()
		highlight_gem2.highlight()
		# Optionally set a timer to remove highlight after a few seconds
		var timer = Timer.new()
		timer.wait_time = 3.0  # 3 seconds
		timer.one_shot = true
		timer.autostart = true
		timer.connect("timeout", self._on_HighlightTimer_timeout)
		add_child(timer)
		timer.start()

func _on_HighlightTimer_timeout():
	if highlight_gem1 and highlight_gem2:
		highlight_gem1.unhighlight()
		highlight_gem2.unhighlight()
		# Reset highlight gems to null
		highlight_gem1 = null
		highlight_gem2 = null

func has_match_at(x, y, board):
	var color = board[x][y].gem_color

	# Check horizontal matches
	var count = 1
	# Check left
	var i = x - 1
	while i >= 0 and board[i][y].gem_color == color:
		count += 1
		i -= 1
	# Check right
	i = x + 1
	while i < board.size() and board[i][y].gem_color == color:
		count += 1
		i += 1
	if count >= 3:
		return true

	# Check vertical matches
	count = 1
	# Check up
	var j = y - 1
	while j >= 0 and board[x][j].gem_color == color:
		count += 1
		j -= 1
	# Check down
	j = y + 1
	while j < board[x].size() and board[x][j].gem_color == color:
		count += 1
		j += 1
	if count >= 3:
		return true
	
	return false

func check_for_possible_moves(hbox:HBoxContainer) -> bool:
	if find_first_possible_swap(hbox).size() > 0:
		return true
	return false

# UTILS

func get_all_matches(hbox:HBoxContainer) -> Array:
	var num_columns: int = hbox.get_child_count()
	var num_rows: int = hbox.get_child(0).get_child_count()
	var matches = []

	# Horizontal Check (check each row)
	for row in range(num_rows):
		var last_color = null
		var streak = 0
		var match_start = 0
		for column in range(num_columns):
			var gem_cell = hbox.get_child(column).get_child(row) as CommonGemCell
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

	# Vertical Check (check each column)
	for column in range(num_columns):
		var last_color = null
		var streak = 0
		var match_start = 0
		for row in range(num_rows):
			var gem_cell = hbox.get_child(column).get_child(row) as CommonGemCell
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
	var all_gem_cells = []
	for match in matches:
		# `match["cells"]` is the array of gem cells for this particular match
		all_gem_cells += match["cells"]  # Append all cells in this match to the master list
	return all_gem_cells

func find_gem_indices(gem_cell:CommonGemCell) -> Dictionary:
	var parent_vbox = gem_cell.get_parent()  # Assuming direct parent is a VBoxContainer
	var hbox = parent_vbox.get_parent()      # Assuming direct parent of VBox is the HBoxContainer
	
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

# =========================================================

func calculate_score_for_matches(matches: Array) -> int:
	var score = 0
	for match in matches:
		var match_length = match["count"]
		# Define scoring logic, e.g., exponential growth for larger matches
		var match_score = match_length * match_length  # Example: score grows quadratically with match length
		score += match_score * GEM_POINTS
	return score

func calculate_scores_for_each_match(matches: Array) -> Dictionary:
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

func delay_time(node: Node, time_sec: float) -> void:
	var tnode = node.get_parent()
	var timer = Timer.new()
	timer.wait_time = time_sec
	timer.one_shot = true
	tnode.add_child(timer)
	timer.start()
	await timer.timeout
	tnode.remove_child(timer)
	timer.queue_free()
