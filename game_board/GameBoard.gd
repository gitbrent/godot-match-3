extends Node2D
class_name GameBoard
# SCENES
@onready var grid_container:GridContainer = $GridContainer
@onready var hbox_container:HBoxContainer = $HBoxContainer
#VARS
var selected_cell_1:GemCell = null
var selected_cell_2:GemCell = null

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	fill_grid()
	fill_hbox()

func _on_cell_click(gem_cell:GemCell):
	print("[_on_cell_click] gem_cell:", find_gem_indices(gem_cell))
	
	# STEP 1: Select GemCell
	if not selected_cell_1:
		selected_cell_1 = gem_cell
	elif selected_cell_1 != gem_cell:
		selected_cell_2 = gem_cell
	
	# DEBUG
	#print("[_on_cell_click] selected_cell_1: ", selected_cell_1)
	#print("[_on_cell_click] selected_cell_2: ", selected_cell_2)
	
	# STEP 2: check selection
	# 2A: if cells not adjecent, swap old selected-1
	# 2B: tween cells if valid
	if selected_cell_1 and selected_cell_2 and are_cells_adjacent(selected_cell_1, selected_cell_2):
		print("TODO: tween")
		#
		var orig_pos_cell_1 = selected_cell_1.global_position
		var orig_pos_cell_2 = selected_cell_2.global_position
		var orig_col_cell_1 = selected_cell_1.get_parent()
		var orig_col_cell_2 = selected_cell_2.get_parent()
		var orig_row_cell_1 = find_gem_indices(selected_cell_1).row
		var orig_row_cell_2 = find_gem_indices(selected_cell_2).row
		# move card-1
		orig_col_cell_1.remove_child(selected_cell_1)
		orig_col_cell_2.add_child(selected_cell_1)
		orig_col_cell_2.move_child(selected_cell_1, orig_row_cell_1)
		# move card-2
		orig_col_cell_2.remove_child(selected_cell_2)
		orig_col_cell_1.add_child(selected_cell_2)
		orig_col_cell_1.move_child(selected_cell_2, orig_row_cell_2)
		#
		selected_cell_1.global_position = orig_pos_cell_1
		selected_cell_1.global_position = orig_pos_cell_2
		var tween = get_tree().create_tween()
		tween.tween_property(selected_cell_1, "global_position", orig_pos_cell_2, 0.25)
		tween.tween_property(selected_cell_2, "global_position", orig_pos_cell_1, 0.25)
		tween.tween_callback(tween_completed.bind(selected_cell_1))
	elif selected_cell_2:
		selected_cell_1 = selected_cell_2
		selected_cell_2 = null

func tween_completed(gem_cell:GemCell):
	print("[TWEEN-COMPLETE]: ", gem_cell)
	selected_cell_1 = null
	selected_cell_2 = null

func are_cells_adjacent(gemcell1: GemCell, gemcell2: GemCell) -> bool:
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

func fill_grid():
	var size = 8  # This is the size of your grid, 8x8 in this case
	for i in range(size):
		for j in range(size):
			# Calculate index from row and column
			var index = i * size + j
			
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

func find_gem_indices(gem_cell: GemCell) -> Dictionary:
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
