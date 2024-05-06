extends Node2D
class_name GameBoard
# SIGNALS
signal gem_swapped()
# SCENES
@onready var grid_container:GridContainer = $GridContainer
@onready var hbox_container:HBoxContainer = $HBoxContainer
#VARS
const TWEEN_TIME:float = 0.25
var selected_cell_1:GemCell = null
var selected_cell_2:GemCell = null
#var explode_me_matched_gems:Array
var undo_cell_1:GemCell = null
var undo_cell_2:GemCell = null

# Called when the node enters the scene tree for the first time.
func _ready():
	# godot setup
	randomize()
	# A: populate board
	fill_grid()
	fill_hbox()
	# B: check board after init
	check_board_explode_matches()

# TODO: feed props to parent controller for display
func get_gem_props():
	var brent:Dictionary = {
		"GREEN": 99
	}
	return brent

# =========================================================

func fill_grid():
	var size = 8  # This is the size of your grid, 8x8 in this case
	for i in range(size):
		for j in range(size):
			# Calculate index from row and column
			#var index = i * size + j
			
			# Load the appropriate scene based on the checkerboard pattern
			var brdsq_scene_path = "res://game_board/board_square_1.tscn"  # Assume light square
			if (i + j) % 2 == 0:
				brdsq_scene_path = "res://game_board/board_square_0.tscn"  # Dark square
			
			# Load and instantiate the scene
			var brdsq_scene = load(brdsq_scene_path)
			var brdsq = brdsq_scene.instantiate()
			
			# Add the instantiated square to the grid container
			grid_container.add_child(brdsq)

func fill_hbox():
	var gem_colors = [Enums.GemColor.WHITE, Enums.GemColor.RED, Enums.GemColor.YELLOW, Enums.GemColor.GREEN, Enums.GemColor.PURPLE]
	for col_idx in range(hbox_container.get_child_count()):
		for row_idx in range(8):
			# A: random gem
			var gem_type = gem_colors[randi() % gem_colors.size()]
			#var gem_type = Enums.GemColor.WHITE
			# B: create/add
			var gem_cell_scene = load("res://game_board/gem_cell.tscn")
			var gem_cell:GemCell = gem_cell_scene.instantiate()
			hbox_container.get_child(col_idx).add_child(gem_cell)
			gem_cell.initialize(gem_type)
			var control_node = gem_cell.get_node("GemControl")
			#control_node.connect("drag_start", self._on_cell_click)
			control_node.connect("cell_click", self._on_cell_click)
			#control_node.connect("drag_ended", self._on_cell_click)

# =========================================================
# NEW!!
# =========================================================

# UTILS

func find_gem_indices(gem_cell:GemCell) -> Dictionary:
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

func are_cells_adjacent(gemcell1:GemCell, gemcell2:GemCell) -> bool:
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

func get_first_match_gems() -> Array:
	var num_columns: int = hbox_container.get_child_count()
	var num_rows: int = hbox_container.get_child(0).get_child_count()  # Assuming uniform row count across columns
	var match_cells: Array = []

	# Horizontal Check (check each row)
	for row in range(num_rows):
		var last_color = null
		var streak = 0
		var match_start = 0
		for column in range(num_columns):
			var gem_cell = hbox_container.get_child(column).get_child(row) as GemCell
			if gem_cell.gem_color == last_color:
				streak += 1
			else:
				if streak >= 3:
					# Collect matching GemCells
					match_cells = []
					for i in range(match_start, column):
						match_cells.append(hbox_container.get_child(i).get_child(row))
					return match_cells
				streak = 1
				match_start = column
				last_color = gem_cell.gem_color
		if streak >= 3:
			match_cells = []
			for i in range(match_start, num_columns):
				match_cells.append(hbox_container.get_child(i).get_child(row))
			return match_cells

	# Vertical Check (check each column)
	for column in range(num_columns):
		var last_color = null
		var streak = 0
		var match_start = 0
		for row in range(num_rows):
			var gem_cell = hbox_container.get_child(column).get_child(row) as GemCell
			if gem_cell.gem_color == last_color:
				streak += 1
			else:
				if streak >= 3:
					# Collect matching GemCells
					match_cells = []
					for i in range(match_start, row):
						match_cells.append(hbox_container.get_child(column).get_child(i))
					return match_cells
				streak = 1
				match_start = row
				last_color = gem_cell.gem_color
		if streak >= 3:
			match_cells = []
			for i in range(match_start, num_rows):
				match_cells.append(hbox_container.get_child(column).get_child(i))
			return match_cells

	return []  # No matches found

# STEP 1: Handle input (=capture first & second selection), swap gems
# @desc: calls `swap_gem_cells()` when 2 cells selected and are adjacent

func _on_cell_click(gem_cell:GemCell):
	print("[_on_cell_click] ---------------------------------------------")
	print("[_on_cell_click] gem_cell.......: ", find_gem_indices(gem_cell))
	
	# Clear first, we'll set later
	if selected_cell_1:
		selected_cell_1.play_selected_anim(false)
	if selected_cell_2:
		selected_cell_2.play_selected_anim(false)
	
	# STEP 1: Select GemCell logic
	if not selected_cell_1:
		selected_cell_1 = gem_cell
	elif selected_cell_1 != gem_cell:
		if are_cells_adjacent(selected_cell_1, gem_cell):
			selected_cell_2 = gem_cell
		else:
			selected_cell_1 = gem_cell
			selected_cell_2 = null
	
	# DEBUG
	if selected_cell_1:
		#print("[_on_cell_click] selected_cell_1: ", find_gem_indices(selected_cell_1))
		selected_cell_1.debug_show_selnum(1)
	if selected_cell_2:
		#print("[_on_cell_click] selected_cell_2: ", find_gem_indices(selected_cell_2))
		selected_cell_2.debug_show_selnum(2)
	
	# STEP 2: effect
	if selected_cell_1:
		selected_cell_1.play_selected_anim(true)
	
	# STEP 3: swap cells if adjacent
	if selected_cell_1 and selected_cell_2 and are_cells_adjacent(selected_cell_1, selected_cell_2):
		undo_cell_1 = selected_cell_1
		undo_cell_2 = selected_cell_2
		swap_gem_cells(selected_cell_1, selected_cell_2)

# STEP 2: Swap gems: capture current gems, move scenes via tween

func swap_gem_cells(swap_cell_1:GemCell, swap_cell_2:GemCell):
	if not swap_cell_1 or not swap_cell_2:
		return
	
	# A: signal game controller
	emit_signal("gem_swapped") # play swipe sound
	
	# B: turn off anim/effects before moving
	swap_cell_1.play_selected_anim(false)
	swap_cell_2.play_selected_anim(false)
	
	# C: get position to restore to after move so tween sets/flows smoothly
	var orig_pos_cell_1 = swap_cell_1.global_position
	var orig_col_cell_1 = swap_cell_1.get_parent()
	var orig_ridx_cell_1 = find_gem_indices(swap_cell_1).row
	#var orig_cidx_cell_1 = find_gem_indices(swap_cell_1).column
	var orig_pos_cell_2 = swap_cell_2.global_position
	var orig_col_cell_2 = swap_cell_2.get_parent()
	var orig_ridx_cell_2 = find_gem_indices(swap_cell_2).row
	#var orig_cidx_cell_2 = find_gem_indices(swap_cell_2).column

	# D: swap gems
	orig_col_cell_1.remove_child(swap_cell_1)
	orig_col_cell_2.add_child(swap_cell_1)
	orig_col_cell_2.move_child(swap_cell_1, orig_ridx_cell_1)
	orig_col_cell_2.remove_child(swap_cell_2)
	orig_col_cell_1.add_child(swap_cell_2)
	orig_col_cell_1.move_child(swap_cell_2, orig_ridx_cell_2)
	
	# IMPORTANT: use deferred to allow changes above to render, then re-position and tween afterwards!
	call_deferred("setup_tween", swap_cell_1, orig_pos_cell_1, orig_pos_cell_2)
	call_deferred("setup_tween", swap_cell_2, orig_pos_cell_2, orig_pos_cell_1)

func setup_tween(gem_cell:GemCell, start_pos:Vector2, end_pos:Vector2):
	gem_cell.global_position = start_pos  # Set initial position right before tweening
	var tween = get_tree().create_tween()
	tween.tween_property(gem_cell, "global_position", end_pos, TWEEN_TIME)
	tween.tween_callback(tween_completed.bind(gem_cell))

# STEP 3: Tween complete: clear vars/scan board

func tween_completed(gem_cell:GemCell):
	#print("[TWEEN-COMPLETE]: ", gem_cell)
	
	# This method w/b called twice - after each gem is moved
	if gem_cell == selected_cell_1:
		selected_cell_1.debug_show_selnum(0)
		selected_cell_1 = null
	elif gem_cell == selected_cell_2:
		selected_cell_2.debug_show_selnum(0)
		selected_cell_2 = null
	
	# This method w/b called twice - after each gem is moved, only run after BOTH done
	if not selected_cell_1 and not selected_cell_2:
		print("CHECK!!")
		check_board_explode_matches()

func check_board_explode_matches():
	print("[check_board_explode_matches]: enter") # We get called too much (3 times after 1 move)
	# FIXME: TODO: ^^^ 
	var gem_matches = get_first_match_gems()
	if gem_matches.size() == 0:
		#await get_tree().create_timer(TWEEN_TIME).timeout
		# Then swap them right back
		swap_gem_cells(undo_cell_2, undo_cell_1)
		undo_cell_1 = null
		undo_cell_2 = null
	else:
		print("[check_board_explode_matches]: MATCHES! ", gem_matches)
		# D3: log gems to explode after move is done
		explode_gems(gem_matches)
		# TODO: EXPLODE LOOP
		pass

# STEP 4: Explode first match found, repeat until exhausted

func explode_gems(gem_cells: Array):
	print("[explode_gems] gems: ", gem_cells)
	print_ascii_table(gem_cells)
	for gem_cell in gem_cells:
		gem_cell.play_anim_explode()
		await get_tree().create_timer(TWEEN_TIME).timeout
		gem_cell.get_parent().remove_child(gem_cell)
		gem_cell.queue_free()
		print("BOOM!!")

# DEBUG

func print_ascii_table(affected_cells: Array):
	var num_columns: int = hbox_container.get_child_count()
	var num_rows: int = hbox_container.get_child(0).get_child_count()  # Assuming all columns have the same number of rows

	# Prepare a grid for ASCII output
	var grid = []
	for i in range(num_rows):
		var row = []  # Create a new row
		for j in range(num_columns):
			row.append(" ")  # Fill the row with spaces
		grid.append(row)  # Add the filled row to the grid

	# Mark the affected cells
	for cell in affected_cells:
		var indices = find_gem_indices(cell)
		if indices["column"] != -1 and indices["row"] != -1:
			grid[indices["row"]][indices["column"]] = "X"

	# Print the ASCII grid
	print("Current Gem Board State:")
	for row in grid:
		print(" | ".join(row))
