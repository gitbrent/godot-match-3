extends Node
class_name CommonDebug

var CmnFunc = preload("res://game_boards/all_common/common.gd").new()

func debug_print_column_ascii(column: VBoxContainer, column_index: int):
	var output = ""
	for i in range(column.get_child_count() - 1, -1, -1):  # Print from top to bottom
		var gem_cell = column.get_child(i) as CommonGemCell
		if gem_cell != null:
			output += "[ " + Enums.get_color_name_by_value(gem_cell.gem_color).substr(0,1) + " ]"  # Append each gem's color to the output string
		else:
			output += "[   ]"  # Append empty brackets for null or missing gems
	print("Column ", column_index, " state: ", output)

func debug_print_ascii_table(hbox:HBoxContainer, affected_cells: Array):
	var num_columns: int = hbox.get_child_count()
	var num_rows: int = hbox.get_child(0).get_child_count()  # Assuming all columns have the same number of rows
	
	# Prepare a grid for ASCII output
	var grid = []
	for i in range(num_rows):
		var row = []
		for j in range(num_columns):
			row.append(" ")  # Add a space to the row for each column
		grid.append(row)  # Add the completed row to the grid
	
	# Mark the affected cells
	for cell in affected_cells:
		var indices = CmnFunc.find_gem_indices(cell)
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

func debug_clear_debug_labels(hbox:HBoxContainer):
	for vbox in hbox.get_children():
		for gem_cell in vbox.get_children():
			gem_cell.debug_show_debug_panel(false)
			gem_cell.get_child(1).visible = true
			gem_cell.get_child(1).position = Enums.SRPITE_POS
			#var debug_name = Enums.get_color_name_by_value(gem_cell.gem_color).substr(0,1)
			#var debug_str = "[debug_clear_debug_labels] ["+debug_name+"] " + str(gem_cell.get_child(1).visible)
			#Enums.debug_print(debug_str, Enums.DEBUG_LEVEL.DEBUG)

func debug_make_match_col(hbox:HBoxContainer, gemDict:Enums.GemDict):
	var col0:VBoxContainer = hbox.get_child(0)
	var col0_child4:CommonGemCell = col0.get_child(4)
	col0_child4.initialize(Enums.GemColor.PRP, gemDict)
	var col0_child5:CommonGemCell = col0.get_child(5)
	col0_child5.initialize(Enums.GemColor.PRP, gemDict)
	var col0_child6:CommonGemCell = col0.get_child(6)
	col0_child6.initialize(Enums.GemColor.PRP, gemDict)
	var col0_child7:CommonGemCell = col0.get_child(7)
	col0_child7.initialize(Enums.GemColor.PRP, gemDict)

func debug_make_gem_grid(hbox:HBoxContainer, gemDict:Enums.GemDict):
	var size = hbox.get_child_count()
	for i in range(size):
		var vbox = hbox.get_child(i)
		for j in range(size):
			var gem = vbox.get_child(j)
			# Load the appropriate scene based on the checkerboard pattern
			gem.initialize(Enums.GemColor.PRP, gemDict)
			if (i + j) % 2 == 0:
				gem.initialize(Enums.GemColor.YLW, gemDict)
				gem.get_child(1).position = Enums.SRPITE_POS

# space/locked cells

func debug_unlock_cells(hbox:HBoxContainer):
	for vbox in hbox.get_children():
		if vbox is VBoxContainer:
			for gem_cell in vbox.get_children():
				if gem_cell.is_locked:
					gem_cell.lock_cell(false)
	
	# Lock just one cell, so we can easily test WINNER scneario
	hbox.get_child(3).get_child(3).lock_cell(true)
