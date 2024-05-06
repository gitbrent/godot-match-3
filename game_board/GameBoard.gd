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
var explode_me_matched_gems: Array

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	fill_grid()
	fill_hbox()

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
		swap_gem_cells()

# TODO: feed props to parent controller for display
func get_gem_props():
	var brent:Dictionary = {
		"GREEN": 99
	}
	return brent

# =========================================================

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

# TODO: Check entire board for any matches (not used yet, will show "NO MOVES" and reload grid)
func check_for_matches() -> bool:
	var num_columns: int = hbox_container.get_child_count()
	var num_rows: int = hbox_container.get_child_count()
	
	# Horizontal Check (check each row)
	for row in range(num_rows):
		var last_color = null
		var streak = 0
		for column in range(num_columns):
			#print("[check_for_matches]: [" + str(row) + "/" + str(column) + "]")
			var gem_cell = $HBoxContainer.get_child(column).get_child(row) as GemCell
			if gem_cell.gem_color == last_color:
				streak += 1
			else:
				if streak >= 3:
					return true  # Found a horizontal match
				streak = 1
				last_color = gem_cell.gem_color
		if streak >= 3:
			return true  # Check if the last streak in the row was a match
	
	# Vertical Check (check each column)
	for column in range(num_columns):
		var last_color = null
		var streak = 0
		for row in range(num_rows):
			var gem_cell = $HBoxContainer.get_child(column).get_child(row) as GemCell
			if gem_cell.gem_color == last_color:
				streak += 1
			else:
				if streak >= 3:
					return true  # Found a vertical match
				streak = 1
				last_color = gem_cell.gem_color
		if streak >= 3:
			return true  # Check if the last streak in the column was a match
	
	return false  # No matches found

func unique_array(array: Array) -> Array:
	var unique_dict: Dictionary = {}
	for item in array:
		unique_dict[item] = true
	return unique_dict.keys()

func get_matched_gems(col: int, row: int) -> Array:
	var matches: Array = []
	var hbox = hbox_container

	# Check horizontally
	matches += get_matches_in_direction(col, row, hbox, -1, 0)  # Left
	matches += get_matches_in_direction(col, row, hbox, 1, 0)   # Right
	if matches.size() > 1:  # Includes the center gem, need at least one more for a match
		matches.append(hbox.get_child(col).get_child(row))  # Add center gem if match found

	# Check vertically
	var vertical_matches: Array = []
	vertical_matches += get_matches_in_direction(col, row, hbox, 0, -1)  # Up
	vertical_matches += get_matches_in_direction(col, row, hbox, 0, 1)   # Down
	if vertical_matches.size() > 1:
		vertical_matches.append(hbox.get_child(col).get_child(row))  # Add center gem if match found
		matches += vertical_matches  # Combine horizontal and vertical matches
	
	return unique_array(matches)  # Remove duplicates if any gem is counted in both directions

func get_matches_in_direction(start_col: int, start_row: int, hbox: HBoxContainer, delta_col: int, delta_row: int) -> Array:
	var matches: Array = []
	var current_col: int = start_col + delta_col
	var current_row: int = start_row + delta_row
	var current_color: Enums.GemColor = (hbox.get_child(start_col).get_child(start_row) as GemCell).gem_color
	while current_col >= 0 and current_col < hbox.get_child_count() and current_row >= 0 and current_row < hbox.get_child(current_col).get_child_count():
		var gem_cell: GemCell = hbox.get_child(current_col).get_child(current_row) as GemCell
		if gem_cell.gem_color == current_color:
			matches.append(gem_cell)
			current_col += delta_col
			current_row += delta_row
		else:
			break
	return matches

func will_create_match(src_cell: GemCell, new_col: int, new_row: int) -> bool:
	print("[will_create_match]: " + Enums.get_color_name_by_value(src_cell.gem_color) + " at c:r " + str(new_col+1) + ":" + str(new_row+1))
	
	# Temporarily swap gems for the purpose of checking
	var tgt_cell: GemCell = hbox_container.get_child(new_col).get_child(new_row) as GemCell
	var original_color: Enums.GemColor = tgt_cell.gem_color
	tgt_cell.gem_color = src_cell.gem_color
	src_cell.gem_color = original_color
	
	# Check for matches
	var matched_gems: Array = get_matched_gems(new_col, new_row)
	print("[will_create_match]: matched_gems: ", matched_gems)
	if matched_gems.size() > 0:
		return true
	
	# Revert colors back if no match is found
	tgt_cell.gem_color = original_color
	src_cell.gem_color = tgt_cell.gem_color
	return false

func check_match_at_position(col: int, row: int, hbox: HBoxContainer) -> bool:
	# Check horizontally
	var min_col = max(col - 2, 0)
	var max_col = min(col + 2, hbox.get_child_count() - 1)
	var current_color = (hbox.get_child(col).get_child(row) as GemCell).gem_color
	var match_count = 1  # Start with the gem itself

	# Check to the left
	for i in range(col - 1, min_col - 1, -1):
		if (hbox.get_child(i).get_child(row) as GemCell).gem_color == current_color:
			match_count += 1
		else:
			break

	# Check to the right
	for i in range(col + 1, max_col + 1):
		if (hbox.get_child(i).get_child(row) as GemCell).gem_color == current_color:
			match_count += 1
		else:
			break

	if match_count >= 3:
		return true  # Horizontal match found

	# Check vertically
	var vbox = hbox.get_child(col) as VBoxContainer
	var min_row = max(row - 2, 0)
	var max_row = min(row + 2, vbox.get_child_count() - 1)
	match_count = 1  # Reset for vertical checking

	# Check upwards
	for i in range(row - 1, min_row - 1, -1):
		if (vbox.get_child(i) as GemCell).gem_color == current_color:
			match_count += 1
		else:
			break

	# Check downwards
	for i in range(row + 1, max_row + 1):
		if (vbox.get_child(i) as GemCell).gem_color == current_color:
			match_count += 1
		else:
			break

	if match_count >= 3:
		return true  # Vertical match found

	return false  # No matches found

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

func swap_gem_cells():
	# A: signal game controller
	emit_signal("gem_swapped") # play swipe sound

	# B: turn off anim/effects before moving
	selected_cell_1.play_selected_anim(false)
	selected_cell_2.play_selected_anim(false)

	# C: get position to restore to after move so tween sets/flows smoothly
	var orig_pos_cell_1 = selected_cell_1.global_position
	var orig_col_cell_1 = selected_cell_1.get_parent()
	var orig_ridx_cell_1 = find_gem_indices(selected_cell_1).row
	var orig_cidx_cell_1 = find_gem_indices(selected_cell_1).column
	var orig_pos_cell_2 = selected_cell_2.global_position
	var orig_col_cell_2 = selected_cell_2.get_parent()
	var orig_ridx_cell_2 = find_gem_indices(selected_cell_2).row
	var orig_cidx_cell_2 = find_gem_indices(selected_cell_2).column

	# D: swap gems, or swap back if no match
	# NOTE: when they dont match, just tween-swap them (dont physially move the scenes, why bother?)
	if will_create_match(selected_cell_1, orig_cidx_cell_2, orig_ridx_cell_2):
		# D1: swap gems
		orig_col_cell_1.remove_child(selected_cell_1)
		orig_col_cell_2.add_child(selected_cell_1)
		orig_col_cell_2.move_child(selected_cell_1, orig_ridx_cell_1)
		orig_col_cell_2.remove_child(selected_cell_2)
		orig_col_cell_1.add_child(selected_cell_2)
		orig_col_cell_1.move_child(selected_cell_2, orig_ridx_cell_2)
		
		# D2: IMPORTANT: use deferred to allow changes above to render, then re-position and tween afterwards!
		call_deferred("setup_tween", selected_cell_1, orig_pos_cell_1, orig_pos_cell_2)
		call_deferred("setup_tween", selected_cell_2, orig_pos_cell_2, orig_pos_cell_1)
	else:
		# Tween to each other's positions
		call_deferred("setup_tween", selected_cell_1, orig_pos_cell_1, orig_pos_cell_2)
		call_deferred("setup_tween", selected_cell_2, orig_pos_cell_2, orig_pos_cell_1)
		# Wait for the first tween to complete
		await get_tree().create_timer(TWEEN_TIME).timeout
		# Then swap them right back
		call_deferred("swap_back", selected_cell_1, selected_cell_2, orig_pos_cell_1, orig_pos_cell_2)

func swap_back(gem_cell_1, gem_cell_2, pos_cell_1, pos_cell_2):
	setup_tween(gem_cell_1, gem_cell_1.global_position, pos_cell_1)
	setup_tween(gem_cell_2, gem_cell_2.global_position, pos_cell_2)

func setup_tween(gem_cell:GemCell, start_pos:Vector2, end_pos:Vector2):
	gem_cell.global_position = start_pos  # Set initial position right before tweening
	var tween = get_tree().create_tween()
	tween.tween_property(gem_cell, "global_position", end_pos, TWEEN_TIME)
	tween.tween_callback(tween_completed.bind(gem_cell))

func tween_completed(gem_cell:GemCell):
	#print("[TWEEN-COMPLETE]: ", gem_cell)
	
	# TODO: WIP: when toget agther correct gems
	var brent = find_gem_indices(gem_cell)
	explode_me_matched_gems = get_matched_gems(brent.column, brent.row)
	print("explode_me_matched_gems: ", explode_me_matched_gems)
	
	# This method w/b called twice - after each gem is moved
	if gem_cell == selected_cell_1:
		selected_cell_1.debug_show_selnum(0)
		selected_cell_1 = null
	elif gem_cell == selected_cell_2:
		selected_cell_2.debug_show_selnum(0)
		selected_cell_2 = null
	
	# This method w/b called twice - after each gem is moved, only run after BOTH done
	if not selected_cell_1 and not selected_cell_2 and explode_me_matched_gems.size() > 0:
		# D3: log gems to explode after move is done
		explode_gems(explode_me_matched_gems)

func explode_gems(gem_cells: Array):
	# Function to handle removal of gems and other effects
	print("Explode gems: ", gem_cells)
	for gem_cell in gem_cells:
		gem_cell.play_anim_explode()
		#await get_tree().create_timer(TWEEN_TIME).timeout
		#gem_cell.get_parent().remove_child(gem_cell)
		#gem_cell.queue_free()
		print("BOOM!!")
	#if selected_cell_1:
		#selected_cell_1.debug_show_selnum(0)
		#selected_cell_1 = null
	#if selected_cell_2:
		#selected_cell_2.debug_show_selnum(0)
		#selected_cell_2 = null
	explode_me_matched_gems.clear()

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
