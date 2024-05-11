# FIXME:
# - gems exploded need ones above to fall down; then missing ones added above
extends Node2D
class_name GameBoard
# SIGNALS
signal gem_swapped()
# SCENES
@onready var grid_container:GridContainer = $GridContainer
@onready var hbox_container:HBoxContainer = $HBoxContainer
#VARS
const GEM_COLOR_NAMES = [Enums.GemColor.WHITE, Enums.GemColor.RED, Enums.GemColor.YELLOW, Enums.GemColor.BROWN, Enums.GemColor.GREEN, Enums.GemColor.PURPLE]
var selected_cell_1:GemCell = null
var selected_cell_2:GemCell = null
var undo_cell_1:GemCell = null
var undo_cell_2:GemCell = null
var tweens_running:int = 0

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
	var size = hbox_container.get_child_count()
	for i in range(size):
		for j in range(size):
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
	for col_idx in range(hbox_container.get_child_count()):
		for row_idx in range(8):
			# A: random gem
			var gem_type = GEM_COLOR_NAMES[randi() % GEM_COLOR_NAMES.size()]
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
	var num_rows: int = hbox_container.get_child(0).get_child_count()
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
	Enums.debug_print("[_on_cell_click] gem_cell.......: "+JSON.stringify(find_gem_indices(gem_cell)), Enums.DEBUG_LEVEL.INFO)
	Enums.debug_print("[_on_cell_click] ---------------------------------------------", Enums.DEBUG_LEVEL.INFO)
	
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
		Enums.debug_print("[_on_cell_click] selected_cell_1: " + JSON.stringify(find_gem_indices(selected_cell_1)), Enums.DEBUG_LEVEL.INFO)
		selected_cell_1.debug_show_selnum(1)
	if selected_cell_2:
		Enums.debug_print("[_on_cell_click] selected_cell_2: " + JSON.stringify(find_gem_indices(selected_cell_2)), Enums.DEBUG_LEVEL.INFO)
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
	emit_signal("gem_swapped") # notify controller (play sound, increase moves counter, etc.)
	
	# B: turn off anim/effects before moving
	swap_cell_1.play_selected_anim(false)
	swap_cell_2.play_selected_anim(false)
	
	# C: logially swap
	var gem_cell_1 = swap_cell_1.gem_color
	var gem_cell_2 = swap_cell_2.gem_color
	swap_cell_1.initialize(gem_cell_2)
	swap_cell_2.initialize(gem_cell_1)
	#debug_print_ascii_table([swap_cell_1,swap_cell_2])
	
	# D: get position to restore to after move so tween sets/flows smoothly
	var orig_pos_cell_1 = swap_cell_1.sprite.position
	var orig_pos_cell_2 = swap_cell_2.sprite.position
	
	# E: re-position and tween
	call_deferred("setup_tween", swap_cell_2, orig_pos_cell_1, orig_pos_cell_2)
	call_deferred("setup_tween", swap_cell_1, orig_pos_cell_2, orig_pos_cell_1)

func setup_tween(gem_cell:GemCell, start_pos:Vector2, end_pos:Vector2):
	gem_cell.sprite.position = start_pos # NOTE: Set initial position right before tweening
	tweens_running += 1
	var tween = get_tree().create_tween()
	tween.tween_property(gem_cell.sprite, "position", end_pos, Enums.TWEEN_TIME)
	tween.tween_callback(tween_completed)

# STEP 3: Tween complete: clear vars/scan board

func tween_completed():
	Enums.debug_print("[tween_completed]: (counter="+str(tweens_running)+")", Enums.DEBUG_LEVEL.INFO)
	# A: update counter
	tweens_running -= 1

	# B: clear selections
	if selected_cell_1:
		selected_cell_1.debug_show_selnum(0) # DEBUG
		selected_cell_1 = null
	if selected_cell_2:
		selected_cell_2.debug_show_selnum(0) # DEBUG
		selected_cell_2 = null
	
	# C: once all tweens complete, check board
	if tweens_running == 0:
		check_board_explode_matches()

# STEP 4: Check board, then explode first match found... (repeat until exhausted)

func check_board_explode_matches():
	Enums.debug_print("[check_board_explode_matches]: =====================================", Enums.DEBUG_LEVEL.INFO)
	Enums.debug_print("[check_board_explode_matches]: CHECKING BOARD...                    ", Enums.DEBUG_LEVEL.INFO)
	Enums.debug_print("[check_board_explode_matches]: =====================================", Enums.DEBUG_LEVEL.INFO)
	
	var gem_matches = get_first_match_gems()
	if gem_matches.size() > 0:
		debug_print_ascii_table(gem_matches)
	if gem_matches.size() == 0:
		Enums.debug_print("[check_board_explode_matches]: No more matches. Board stable.", Enums.DEBUG_LEVEL.INFO)
		# Reset undo cells or perform other cleanup here.
		if undo_cell_1 and undo_cell_2:
			swap_gem_cells(undo_cell_2, undo_cell_1)
			undo_cell_1 = null
			undo_cell_2 = null
	else:
		# A: clear undo (swap back) info upon successful match
		undo_cell_1 = null
		undo_cell_2 = null
		# B: explode matched gems
		explode_refill_gems(gem_matches)

func explode_refill_gems(gem_cells: Array):
	Enums.debug_print("[explode_refill_gems........]: =====================================", Enums.DEBUG_LEVEL.INFO)
	Enums.debug_print("[explode_refill_gems........]: *EXPLODING* gem_cell count: "+str(gem_cells.size()), Enums.DEBUG_LEVEL.INFO)
	Enums.debug_print("[explode_refill_gems........]: =====================================", Enums.DEBUG_LEVEL.INFO)
	if Enums.current_debug_level == Enums.DEBUG_LEVEL.DEBUG:
		debug_print_ascii_table(gem_cells)
	
	# A: explode selected
	for gem_cell in gem_cells:
		gem_cell.explode_gem(gem_cell.gem_color)
	await get_tree().create_timer(Enums.EXPLODE_DELAY).timeout
	
	# B: Dictionary to track columns and the number of gems to add in each column
	var columns_to_refill = {}
	for gem_cell in gem_cells:
		var column_index = gem_cell.get_parent().get_index()
		var row_index = gem_cell.get_index()
		if column_index in columns_to_refill:
			columns_to_refill[column_index]["count"] += 1
			columns_to_refill[column_index]["highest"] = max(columns_to_refill[column_index]["highest"], row_index)
		else:
			columns_to_refill[column_index] = {"highest": row_index, "count": 1}
	
	# C: Process each column that needs refilling
	for column_index in columns_to_refill.keys():
		var details = columns_to_refill[column_index]
		refill_column(column_index, details["highest"], details["count"])
	
	# D:
	check_board_explode_matches()

func refill_column(column_index: int, highest_exploded_row: int, count_exploded: int):
	var column = hbox_container.get_child(column_index)
	var debug_str = "[refill_column] | colIdx: "+str(column_index)+" | hst_exp_row: "+str(highest_exploded_row)+" | count_exploded: "+str(count_exploded)
	Enums.debug_print(debug_str, Enums.DEBUG_LEVEL.DEBUG)
	
	# Move gems down from the row just above the first exploded row to the top
	# EXAMPLE:
	#|   | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 
	#|---|---|---|---|---|---|---|---|---|
	#| 0 |   |   |   |   |   |   |   |   |
	#| 1 | G | G | G |   |   |   |   |   |
	# =
	# EX: move gems from rowIdx=0 (0:0,0:2) down to rowIdx=1
	for i in range(highest_exploded_row - count_exploded, -1, -1):
		var source_gem_cell = column.get_child(i)
		var target_gem_cell = column.get_child(i + count_exploded)
		var rows_to_fall = count_exploded
		var debug_str2 = "[---------move] ["+str(i)+"] OLD->NEW: "+Enums.get_color_name_by_value(target_gem_cell.gem_color).substr(0,1)+ "->"+ Enums.get_color_name_by_value(source_gem_cell.gem_color).substr(0,1)+" ... rows_to_fall="+ str(rows_to_fall)
		Enums.debug_print(debug_str2, Enums.DEBUG_LEVEL.DEBUG)
		target_gem_cell.replace_gem(source_gem_cell.gem_color, rows_to_fall)
	
	# Refill the topmost cell(s) with new gems
	for i in range(count_exploded):
		var gem_cell = column.get_child(i)
		var random_color = GEM_COLOR_NAMES[randi() % GEM_COLOR_NAMES.size()]
		gem_cell.replace_gem(random_color)  # Replace top gem with a new random gem
		var debug_str3 = "[-------refill] ["+str(i)+"] ADD: " + Enums.get_color_name_by_value(random_color)
		Enums.debug_print(debug_str3, Enums.DEBUG_LEVEL.DEBUG)

# DEBUG =======================================================================

func debug_print_column_ascii(column: VBoxContainer, column_index: int):
	var output = ""
	for i in range(column.get_child_count() - 1, -1, -1):  # Print from top to bottom
		var gem_cell = column.get_child(i) as GemCell
		if gem_cell != null:
			output += "[ " + Enums.get_color_name_by_value(gem_cell.gem_color).substr(0,1) + " ]"  # Append each gem's color to the output string
		else:
			output += "[   ]"  # Append empty brackets for null or missing gems
	print("Column ", column_index, " state: ", output)

func debug_print_ascii_table(affected_cells: Array):
	var num_columns: int = hbox_container.get_child_count()
	var num_rows: int = hbox_container.get_child(0).get_child_count()  # Assuming all columns have the same number of rows
	
	# Prepare a grid for ASCII output
	var grid = []
	for i in range(num_rows):
		var row = []
		for j in range(num_columns):
			row.append(" ")  # Add a space to the row for each column
		grid.append(row)  # Add the completed row to the grid
	
	# Mark the affected cells
	for cell in affected_cells:
		var indices = find_gem_indices(cell)
		if indices["column"] != -1 and indices["row"] != -1:
			grid[indices["row"]][indices["column"]] = Enums.get_color_name_by_value(cell.gem_color).substr(0,1)
	
	# Print the ASCII grid
	# Header for column indices
	var header = "|   | "  # Start with space for row index column
	for i in range(num_columns):
		header += str(i) + " | "

	# Divider
	var divider = "|"
	for i in range(num_columns + 1):  # +1 for the row index column
		divider += "---|"

	print(header)
	print(divider)
	
	# Print each row with row index and leading/trailing vertical bars
	for i in range(num_rows):
		var row_output = "| " + str(i) + " | " + " | ".join(grid[i]) + " |"
		print(row_output)

	# Closing divider
	print(divider)

func new_game():
	Enums.debug_print("Starting new game, resetting board.", Enums.DEBUG_LEVEL.INFO)
	# A:
	for vbox in hbox_container.get_children():
		for gem_cell in vbox.get_children():
			gem_cell.initialize(GEM_COLOR_NAMES[randi() % GEM_COLOR_NAMES.size()])
			gem_cell.get_child(1).visible = true
			gem_cell.get_child(1).position = Vector2(32,32)
	# B:
	check_board_explode_matches()

func debug_clear_debug_labels():
	for vbox in hbox_container.get_children():
		for gem_cell in vbox.get_children():
			gem_cell.debug_show_debug_panel(false)
			gem_cell.get_child(1).visible = true
			gem_cell.get_child(1).position = Vector2(32,32)
			var debug_name = Enums.get_color_name_by_value(gem_cell.gem_color).substr(0,1)
			var debug_str = "["+debug_name+"] " + str(gem_cell.get_child(1).visible)
			Enums.debug_print(debug_str, Enums.DEBUG_LEVEL.DEBUG)

func debug_make_match_col():
	var col0:VBoxContainer = hbox_container.get_child(0)
	var col0_child4:GemCell = col0.get_child(4)
	col0_child4.initialize(Enums.GemColor.GREEN)
	var col0_child5:GemCell = col0.get_child(5)
	col0_child5.initialize(Enums.GemColor.GREEN)
	var col0_child6:GemCell = col0.get_child(6)
	col0_child6.initialize(Enums.GemColor.GREEN)
	var col0_child7:GemCell = col0.get_child(7)
	col0_child7.initialize(Enums.GemColor.GREEN)

func debug_make_gem_grid():
	var size = hbox_container.get_child_count()
	for i in range(size):
		var vbox = hbox_container.get_child(i)
		for j in range(size):
			var gem = vbox.get_child(j)
			# Load the appropriate scene based on the checkerboard pattern
			gem.initialize(Enums.GemColor.GREEN)
			if (i + j) % 2 == 0:
				gem.initialize(Enums.GemColor.WHITE)
