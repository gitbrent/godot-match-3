extends Node
class_name Common

const GEM_COLOR_NAMES = [Enums.GemColor.WHITE, Enums.GemColor.RED, Enums.GemColor.YELLOW, Enums.GemColor.GREEN, Enums.GemColor.PURPLE, Enums.GemColor.BROWN]
const GEM_POINTS:int = 25

# =========================================================

func fill_grid(hbox:HBoxContainer, grid:GridContainer):
	var size = hbox.get_child_count()
	for i in range(size):
		for j in range(size):
			# Load the appropriate scene based on the checkerboard pattern
			var brdsq_scene_path = "res://game_boards/board_space/game_board/board_square_1.tscn"  # Assume light square
			if (i + j) % 2 == 0:
				brdsq_scene_path = "res://game_boards/board_space/game_board/board_square_0.tscn"  # Dark square
			
			# Load and instantiate the scene
			var brdsq_scene = load(brdsq_scene_path)
			var brdsq = brdsq_scene.instantiate()
			
			# Add the instantiated square to the grid container
			grid.add_child(brdsq)

func fill_hbox(hbox:HBoxContainer, on_cell_click):
	for col_idx in range(hbox.get_child_count()):
		for row_idx in range(8):
			# A: random gem
			var gem_type = GEM_COLOR_NAMES[randi() % GEM_COLOR_NAMES.size()]
			# B: create/add
			var gem_cell_scene = load("res://game_boards/all_common/cmn_gem_cell.tscn")
			var gem_cell:CommonGemCell = gem_cell_scene.instantiate()
			hbox.get_child(col_idx).add_child(gem_cell)
			gem_cell.initialize(gem_type)
			var control_node = gem_cell.get_node("GemControl")
			control_node.connect("cell_click", on_cell_click)
			#control_node.connect("drag_start", self._on_cell_click) # TODO:
			#control_node.connect("drag_ended", self._on_cell_click) # TODO:

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

func delay_time(node: Node, delay: float) -> void:
	var tnode = node.get_parent()
	var timer = Timer.new()
	timer.wait_time = delay
	timer.one_shot = true
	tnode.add_child(timer)
	timer.start()
	await timer.timeout
	tnode.remove_child(timer)
	timer.queue_free()
