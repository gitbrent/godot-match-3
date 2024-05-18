extends Node2D
class_name GameBoard
# SIGNALS
signal props_updated_moves(moves:int)
signal props_updated_score(score:int)
signal props_updated_gemsdict(gems_dict:Dictionary)
signal board_match_multi(match_cnt:int)
# SCENES
@onready var grid_container:GridContainer = $GridContainer
@onready var hbox_container:HBoxContainer = $HBoxContainer
#VARS
var CmnFunc = preload("res://game_boards/all_common/common.gd").new()
var CmnDbg = preload("res://game_boards/all_common/common_debug.gd").new()
const GEM_COLOR_NAMES = [Enums.GemColor.WHITE, Enums.GemColor.RED, Enums.GemColor.YELLOW, Enums.GemColor.GREEN, Enums.GemColor.PURPLE, Enums.GemColor.BROWN]
const GEM_POINTS:int = 25
var selected_cell_1:CommonGemCell = null
var selected_cell_2:CommonGemCell = null
var undo_cell_1:CommonGemCell = null
var undo_cell_2:CommonGemCell = null
var tweens_running_cnt:int = 0
var board_props_moves:int = 0
var board_props_score:int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	# godot setup
	randomize()
	# A: populate board
	CmnFunc.fill_grid(hbox_container, grid_container)
	CmnFunc.fill_hbox(hbox_container, self._on_cell_click)
	# B: check board after init
	process_game_round()

func new_game():
	Enums.debug_print("Starting new game, resetting board.", Enums.DEBUG_LEVEL.INFO)
	# A:
	board_props_moves = 0
	board_props_score = 0
	# B:
	CmnFunc.new_game_explode_replace(hbox_container, GEM_COLOR_NAMES, Enums.EXPLODE_DELAY)
	# C:
	process_game_round()

# =========================================================

# STEP 1: Handle input (=capture first & second selection), swap gems
# @desc: calls `swap_gem_cells()` when 2 cells selected and are adjacent

func _on_cell_click(gem_cell:CommonGemCell):
	Enums.debug_print("[_on_cell_click] gem_cell.......: "+JSON.stringify(CmnFunc.find_gem_indices(gem_cell)), Enums.DEBUG_LEVEL.INFO)
	Enums.debug_print("[_on_cell_click] ---------------------------------------------", Enums.DEBUG_LEVEL.INFO)
	
	# Clear first, we'll set later
	if selected_cell_1:
		selected_cell_1.play_selected_anim(false)
	if selected_cell_2:
		selected_cell_2.play_selected_anim(false)
	
	# STEP 1: Select CommonGemCell logic
	if not selected_cell_1:
		selected_cell_1 = gem_cell
	elif selected_cell_1 != gem_cell:
		if CmnFunc.are_cells_adjacent(selected_cell_1, gem_cell):
			selected_cell_2 = gem_cell
		else:
			selected_cell_1 = gem_cell
			selected_cell_2 = null
	
	# DEBUG
	if selected_cell_1:
		Enums.debug_print("[_on_cell_click] selected_cell_1: " + JSON.stringify(CmnFunc.find_gem_indices(selected_cell_1)), Enums.DEBUG_LEVEL.INFO)
		if Enums.current_debug_level == Enums.DEBUG_LEVEL.DEBUG:
			selected_cell_1.debug_show_selnum(1)
	if selected_cell_2:
		Enums.debug_print("[_on_cell_click] selected_cell_2: " + JSON.stringify(CmnFunc.find_gem_indices(selected_cell_2)), Enums.DEBUG_LEVEL.INFO)
		if Enums.current_debug_level == Enums.DEBUG_LEVEL.DEBUG:
			selected_cell_2.debug_show_selnum(2)
	
	# STEP 2: effect
	if selected_cell_1:
		selected_cell_1.play_selected_anim(true)
	
	# STEP 3: swap cells if adjacent
	if selected_cell_1 and selected_cell_2 and CmnFunc.are_cells_adjacent(selected_cell_1, selected_cell_2):
		undo_cell_1 = selected_cell_1
		undo_cell_2 = selected_cell_2
		swap_gem_cells(selected_cell_1, selected_cell_2)

# STEP 2: Swap gems: capture current gems, move scenes via tween

func swap_gem_cells(swap_cell_1:CommonGemCell, swap_cell_2:CommonGemCell):
	if not swap_cell_1 or not swap_cell_2:
		return
	
	# A: signal game controller
	swap_cell_1.play_audio_gem_move()
	swap_cell_2.play_audio_gem_move()
	
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
	var orig_pos_cell_1 = swap_cell_1.sprite.global_position
	var orig_pos_cell_2 = swap_cell_2.sprite.global_position
	
	# E: re-position and tween
	call_deferred("setup_tween", swap_cell_2, orig_pos_cell_1, orig_pos_cell_2)
	call_deferred("setup_tween", swap_cell_1, orig_pos_cell_2, orig_pos_cell_1)
	
	# F:
	signal_game_props_count_gems()

func setup_tween(gem_cell:CommonGemCell, start_pos:Vector2, end_pos:Vector2):
	gem_cell.sprite.global_position = start_pos # NOTE: Set initial position right before tweening
	tweens_running_cnt += 1
	var tween = get_tree().create_tween()
	tween.tween_property(gem_cell.sprite, "global_position", end_pos, Enums.TWEEN_TIME)
	tween.tween_callback(tween_completed)

# STEP 3: Tween complete: clear vars/scan board

func tween_completed():
	Enums.debug_print("[tween_completed]: (counter="+str(tweens_running_cnt)+")", Enums.DEBUG_LEVEL.INFO)
	# A: update counter
	tweens_running_cnt -= 1

	# B: clear selections
	if selected_cell_1:
		selected_cell_1.debug_show_selnum(0) # DEBUG
		selected_cell_1 = null
	if selected_cell_2:
		selected_cell_2.debug_show_selnum(0) # DEBUG
		selected_cell_2 = null
	
	# C: once all tweens complete, check board
	if tweens_running_cnt == 0:
		process_game_round()

# STEP 4: Check board, then explode first match found... (repeat until exhausted)

func process_game_round():
	Enums.debug_print("[process_game_round]: =====================================", Enums.DEBUG_LEVEL.INFO)
	Enums.debug_print("[process_game_round]: CHECKING BOARD...                    ", Enums.DEBUG_LEVEL.INFO)
	Enums.debug_print("[process_game_round]: =====================================", Enums.DEBUG_LEVEL.INFO)
	
	# A:
	# EX:
	# matches[
	#   {
	#     "cells":["@Control@112:<Control#89338678177>","@Control@113:<Control#90143984570>","@Control@114:<Control#90949290963>"],
	#     "count":3},
	#   {
	#     "cells":["@Control@119:<Control#95781129321>","@Control@120:<Control#96586435714>","@Control@121:<Control#97391742107>"],
	#     "count":3
	#   }
	#]
	var matches = CmnFunc.get_all_matches(hbox_container)
	var gem_cells = CmnFunc.extract_gem_cells_from_matches(matches)
	Enums.debug_print("[process_game_round]: matches.. = "+JSON.stringify(matches), Enums.DEBUG_LEVEL.DEBUG)
	Enums.debug_print("[process_game_round]: gem_cells = "+str(gem_cells), Enums.DEBUG_LEVEL.DEBUG)
	if matches.size() > 0 and Enums.current_debug_level == Enums.DEBUG_LEVEL.DEBUG:
		CmnDbg.debug_print_ascii_table(hbox_container, gem_cells)

	# B:
	var score = CmnFunc.calculate_score_for_matches(matches)
	board_props_score += score
	emit_signal("props_updated_score", board_props_score)
	
	# C: Update UI or game state as necessary
	signal_game_props_count_gems()
	
	# D: Handle resuolts: explode matches, or halt
	if matches.size() == 0:
		Enums.debug_print("[check_board_explode_matches]: No more matches. Board stable.", Enums.DEBUG_LEVEL.INFO)
		# A:
		# B: TODO: check for "NO MORE MOVES"
		# C: Reset undo cells or perform other cleanup here.
		if undo_cell_1 and undo_cell_2:
			swap_gem_cells(undo_cell_2, undo_cell_1)
			undo_cell_1 = null
			undo_cell_2 = null
	else:
		# A: clear undo (swap back) info upon successful match
		undo_cell_1 = null
		undo_cell_2 = null
		# B:
		board_props_moves += 1
		emit_signal("props_updated_moves", board_props_moves)
		# B: explode matched gems
		var match_scores = CmnFunc.calculate_scores_for_each_match(matches)
		explode_refill_gems(matches, match_scores)

func explode_refill_gems(matches: Array, match_scores: Dictionary):
	Enums.debug_print("[explode_refill_gems]: !!!!!!!!!!!=====================================", Enums.DEBUG_LEVEL.INFO)
	Enums.debug_print("[explode_refill_gems]: *EXPLODING* gem_cell count: "+str(matches.size()), Enums.DEBUG_LEVEL.INFO)
	Enums.debug_print("[explode_refill_gems]: !!!!!!!!!!!=====================================", Enums.DEBUG_LEVEL.INFO)
	if Enums.current_debug_level == Enums.DEBUG_LEVEL.DEBUG:
		CmnDbg.debug_print_ascii_table(hbox_container, CmnFunc.extract_gem_cells_from_matches(matches))
	
	# A: explode selected
	for match in matches:
		for gem_cell in match["cells"]:
			var score = match_scores[gem_cell]
			gem_cell.explode_gem(gem_cell.gem_color, score)
	
	# B: Show game messages (ex: "Amazing!")
	emit_signal("board_match_multi", matches.size())
	
	# TODO: FIXME: gem counts need to update faster (they currently update after the animation completes)!!
	# seemingly, this would work fine located here but its not - the UI update requires a frame update i guess?
	signal_game_props_count_gems()
	
	# B: let explode animation run
	await get_tree().create_timer(Enums.TWEEN_TIME).timeout
	
	# C: Dictionary to track columns and the number of gems to add in each column
	var columns_to_refill = {}
	for match in matches:
		for gem_cell in match["cells"]:
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
	await get_tree().create_timer(Enums.EXPLODE_DELAY).timeout # let refill animations above complete (otherwise new, matching gems would start exploding before they're even in place!)
	process_game_round()

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

func signal_game_props_count_gems():
	var gems_dict = {}
	# Initialize dictionary with all gem types set to 0
	for color in Enums.GemColor.values():
		gems_dict[Enums.get_color_name_by_value(color)] = 0
	
	# Assuming you have a way to iterate over all gem nodes
	# For example, if all gems are children of a node called "GemsContainer"
	for col in hbox_container.get_children():
		for gem in col.get_children():
			var color_name = Enums.get_color_name_by_value(gem.gem_color)
			gems_dict[color_name] += 1
	
	# Emit signal with the updated gems dictionary
	emit_signal("props_updated_gemsdict", gems_dict)
