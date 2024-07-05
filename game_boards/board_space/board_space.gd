extends Node2D
class_name GemBoardSpace
# SIGNALS
signal props_updated_moves(moves:int)
signal props_updated_score(score:int)
signal props_updated_gemsdict(gems_dict:Dictionary)
signal board_match_multi(match_cnt:int)
signal show_game_msg(msg:String)
signal show_game_winner()
# SCENES
@onready var grid_container:GridContainer = $GridContainer
@onready var hbox_container:HBoxContainer = $HBoxContainer
@onready var inactivity_timer:Timer = $InactivityTimer
@onready var debug_cont_label:Label = $"../../ContDebug/VBoxContainer/ContDebugLabel"
@onready var debug_cont_value:Label = $"../../ContDebug/VBoxContainer/ContDebugValue"
@onready var debug_cell_value_1 = $"../../ContDebugCellSel/VBoxContainer/CellValue1"
@onready var debug_cell_value_2 = $"../../ContDebugCellSel/VBoxContainer/CellValue2"
@onready var debug_cell_value_tgt = $"../../ContDebugCellSel/VBoxContainer/CellValue3"
@onready var debug_cell_value_sts = $"../../ContDebugCellSel/VBoxContainer/CellValue4"
@onready var debug_cell_value_isd = $"../../ContDebugCellSel/VBoxContainer/CellValue5"
@onready var debug_value_pos_x = $"../../ContDebugCellSel/VBoxContainer/ValuePosX"
@onready var debug_value_pos_y = $"../../ContDebugCellSel/VBoxContainer/ValuePosY"
@onready var space_progress_bar:SpaceProgressBar = $"../../ContTopBar/SpaceProgressBar"
# PRELOAD
var CmnFunc = preload("res://game_boards/all_common/common.gd").new()
var CmnDbg = preload("res://game_boards/all_common/common_debug.gd").new()
# CONST
const GEM_COLOR_NAMES = [Enums.GemColor.RED, Enums.GemColor.ORG, Enums.GemColor.YLW, Enums.GemColor.GRN, Enums.GemColor.BLU, Enums.GemColor.PRP]
const GEM_DICT:Enums.GemDict = Enums.GemDict.SPACE
const GEM_POINTS:int = 25
# VARS
var is_dragging:bool = false
var is_new_game:bool = false
var selected_cell_1:CommonGemCell = null
var selected_cell_2:CommonGemCell = null
var current_target_cell:CommonGemCell = null
var undo_cell_1:CommonGemCell = null
var undo_cell_2:CommonGemCell = null
var tweens_running_cnt:int = 0
var board_props_moves:int = 0
var board_props_score:int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	# godot setup
	randomize()
	inactivity_timer.wait_time = Enums.HINT_DELAY # sync UI to logic
	# A: populate board
	const brd_sq0 = "res://game_boards/board_space/assets/board_square_0.tscn"
	const brd_sq1 = "res://game_boards/board_space/assets/board_square_1.tscn"
	CmnFunc.fill_grid(hbox_container, grid_container, brd_sq0, brd_sq1)

func _process(_delta):
	# DEBUG: show timer
	#debug_cont_label.text = "TIMER Left (secs)"
	#debug_cont_value.text = str(round(inactivity_timer.time_left))
	
	# DEBUG: show selected cells (debugging touch drag sucks)
	if selected_cell_1:
		debug_cont_label.text = selected_cell_1.to_string()
	else:
		debug_cont_label.text = "[null]"
	if selected_cell_2:
		debug_cont_value.text = selected_cell_2.to_string()
	else:
		debug_cont_value.text = "[null]"

# NOTE: iOS [Xcode] has no cells if "CmnFunc.fill_hbox()" is in the _ready() func above
# So, instead of having [game_space.gd] flip `visible` flag on this scene, let's do both of these here to alleviate the issue
# Plus, even when calling both fill_grid funcs, then "process_game_round()" - it made the matching sound sin the background on main game launch, etc.
func init_game():
	# IMPORTANT: This game scene was just made visible before this func is called, 
	# so give the engine a render frame to set the HBoxs or they wont exist yet
	call_deferred("init_game2")

func init_game2():
	# A: clear all GemCells
	for vbox in hbox_container.get_children():
		for cell in vbox.get_children():
			vbox.remove_child(cell)
			cell.queue_free()
	# B: show awesome welcome message
	emit_signal("show_game_msg", "Let's Play!")
	# C: delay to let message complete animation
	await CmnFunc.delay_time(self.get_child(0), 0.5) # (Animation runtime for msg is 0.5-sec)
	# D: do this hre instead of _ready() as iOS/Xcode wont fill cells when invisible or something like that
	CmnFunc.fill_hbox(hbox_container, GEM_DICT, self._on_cell_click, self._on_drag_start, self._on_drag_inprog, self._on_drag_ended)
	# LAST:
	new_game()

func new_game():
	Enums.debug_print("Starting new game, resetting board.", Enums.DEBUG_LEVEL.INFO)
	
	# FIRST: flag new game
	is_new_game = true
	
	# A:
	board_props_moves = 0
	board_props_score = 0
	emit_signal("props_updated_score", board_props_score)
	emit_signal("props_updated_moves", board_props_moves)
	
	# B:
	CmnFunc.unlock_all_gems(hbox_container)
	CmnFunc.new_game_explode_replace(hbox_container, GEM_COLOR_NAMES, Enums.EXPLODE_DELAY)
	
	# C: check board after init (wait for UI updates)
	await CmnFunc.delay_time(self, Enums.EXPLODE_DELAY)
	process_game_round()
	
	# LAST: start inactivity timer
	inactivity_timer.start()

func _on_inactivity_timer_timeout():
	# A: Deselect all (e.g.: maybe one gem was clicked on and is just pulsating on screen)
	# TODO: ^^^
	# B: Call the highlight function on timeout
	if not is_dragging:
		CmnFunc.highlight_first_swap(hbox_container)
	# C: Restart timer
	inactivity_timer.start()

# =========================================================

# STEP 1: Handle input (=capture first & second selection), swap gems
# @desc: calls `swap_gem_cells()` when 2 cells selected and are adjacent

func _on_cell_click(gem_cell:CommonGemCell):
	Enums.debug_print("[_on_cell_click] gem_cell.......: "+JSON.stringify(CmnFunc.find_gem_indices(gem_cell)), Enums.DEBUG_LEVEL.INFO)
	Enums.debug_print("[_on_cell_click] ---------------------------------------------", Enums.DEBUG_LEVEL.INFO)
	debug_cell_value_sts.text = "_on_cell_click"
	
	# A: [GAME-SPECIFIC]: Locked cells
	if gem_cell.is_locked:
		return
	
	# TODO: Also: add block clicks during `explode_refill_gems()`!!!
	# A: Dont allow selection while tweens are running!
	if tweens_running_cnt > 0:
		return
	
	# A: Reset the inactivity_timer timer on any user input
	inactivity_timer.stop()
	inactivity_timer.start()
	
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
	debug_cell_value_1.text = "-"
	debug_cell_value_2.text = "-"
	if selected_cell_1:
		var formated_1 = CmnFunc.format_gem_indices(CmnFunc.find_gem_indices(selected_cell_1))
		debug_cell_value_1.text = formated_1
		Enums.debug_print("[_on_cell_click] selected_cell_1: " + formated_1, Enums.DEBUG_LEVEL.INFO)
		if Enums.current_debug_level == Enums.DEBUG_LEVEL.DEBUG:
			selected_cell_1.debug_show_selnum(1)
	if selected_cell_2:
		var formated_2 = CmnFunc.format_gem_indices(CmnFunc.find_gem_indices(selected_cell_2))
		debug_cell_value_2.text = formated_2
		Enums.debug_print("[_on_cell_click] selected_cell_2: " + formated_2, Enums.DEBUG_LEVEL.INFO)
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

func _on_drag_start(_gem_cell:CommonGemCell, _mouse_position:Vector2):
	debug_cell_value_sts.text += "\n_on_drag_start"

	# TODO: Also block during `explode_refill_gems()`!!!
	# A: Dont allow selection while tweens are running!
	if tweens_running_cnt > 0:
		return
	
	# B: Set
	is_dragging = true

func _on_drag_inprog(_gem_cell:CommonGemCell, mouse_position:Vector2):
	debug_cell_value_isd.text = str(is_dragging)
	#print("[_on_drag_inprog] gem_cell.......: "+JSON.stringify(CmnFunc.find_gem_indices(gem_cell)))
	if is_dragging:
		var target_cell = CmnFunc.get_gem_at_position(mouse_position, hbox_container)
		if target_cell:
			debug_cell_value_tgt.text = CmnFunc.format_gem_indices(CmnFunc.find_gem_indices(target_cell))
		else:
			debug_cell_value_tgt.text = "-"
		debug_value_pos_x.text = str(round(mouse_position.x))
		debug_value_pos_y.text = str(round(mouse_position.y))
		#print("[_on_drag_inprog] target_cell.......: "+JSON.stringify(CmnFunc.find_gem_indices(target_cell)))
		if target_cell and selected_cell_1 and CmnFunc.are_cells_adjacent(selected_cell_1, target_cell):
			if current_target_cell and current_target_cell != target_cell and selected_cell_1 != current_target_cell:
				current_target_cell.play_selected_anim(false)
			current_target_cell = target_cell
			if selected_cell_1:
				selected_cell_1.play_selected_anim(true)
			current_target_cell.play_selected_anim(true)
		elif current_target_cell:
			current_target_cell.play_selected_anim(false) # turn off previously anim cell as current cell is invalid choice

func _on_drag_ended(gem_cell:CommonGemCell, mouse_position:Vector2):
	debug_cell_value_sts.text += "\n_on_drag_ended"
	if is_dragging:
		if current_target_cell:
			current_target_cell.play_selected_anim(false)
			current_target_cell = null
		var target_cell:CommonGemCell = CmnFunc.get_gem_at_position(mouse_position, hbox_container)
		if target_cell and CmnFunc.are_cells_adjacent(gem_cell, target_cell):
			undo_cell_1 = gem_cell
			undo_cell_2 = target_cell
			swap_gem_cells(gem_cell, target_cell)
		elif target_cell and selected_cell_1 and target_cell != selected_cell_1:
			# the target was invalid on drag end, so go ahead and unselected cell-1 (reset state)
			selected_cell_1.play_selected_anim(false)
			selected_cell_1 = null
			debug_cell_value_1.text = "-"
	# DONE
	is_dragging = false
	#debug_cell_value_tgt.text = "-"
	#debug_value_pos_x.text = "-"
	#debug_value_pos_y.text = "-"
	#debug_cell_value_isd.text = "-"

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
	swap_cell_1.initialize(gem_cell_2, GEM_DICT)
	swap_cell_2.initialize(gem_cell_1, GEM_DICT)
	
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
	var all_matches = CmnFunc.get_all_matches(hbox_container)
	Enums.debug_print("[process_game_round]: all_matches.. = "+CmnDbg.print_gem_matches(all_matches), Enums.DEBUG_LEVEL.DEBUG)
	#if all_matches.size() > 0 and Enums.current_debug_level == Enums.DEBUG_LEVEL.DEBUG:
	#	CmnDbg.debug_print_ascii_table(hbox_container, all_matches)
	
	# B:
	var score = CmnFunc.calculate_score_for_matches(all_matches)
	board_props_score += score
	emit_signal("props_updated_score", board_props_score)
	
	# C: Update UI or game state as necessary
	signal_game_props_count_gems()
	
	# D: Handle resuolts: explode matches, or halt
	if all_matches.size() == 0:
		Enums.debug_print("[check_board_explode_matches]: No more matches. Board stable.", Enums.DEBUG_LEVEL.INFO)
		# A: TODO: check for "NO MORE MOVES"
		var brent = CmnFunc.check_for_possible_moves(hbox_container)
		#print("TODO: HANDLE NO MOVES = ", str(brent))
		# TODO: Handle no-more-moves (show msg; explode all (Same as new game btn))
		# B: Reset undo cells or perform other cleanup here.
		if undo_cell_1 and undo_cell_2:
			swap_gem_cells(undo_cell_2, undo_cell_1)
			undo_cell_1 = null
			undo_cell_2 = null
		# LAST: handle startup
		if is_new_game:
			Enums.debug_print("[check_board_explode_matches]: is_new_game!", Enums.DEBUG_LEVEL.INFO)
			# *GAME-SPECIFIC*: frozen gems
			await CmnFunc.delay_time(self.get_child(0), Enums.TWEEN_TIME)
			CmnFunc.lock_bottom_two_rows(hbox_container)
			space_progress_bar.set_progbar(0)
			is_new_game = false
	else:
		# A: clear undo (swap back) info upon successful match
		undo_cell_1 = null
		undo_cell_2 = null
		# B:
		board_props_moves += 1
		emit_signal("props_updated_moves", board_props_moves)
		# B: explode matched gems
		var match_scores = CmnFunc.calculate_scores_for_each_match(all_matches)
		explode_refill_gems(all_matches, match_scores)

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
			# WIP: locked cells
			var prog = 16 - CmnFunc.count_locked_cells(hbox_container)
			space_progress_bar.set_progbar(prog)
	
	# A: [GAME-RULE] WINNER if all cells unlocked
	# DESC: Check for no more locked gems *HERE* not in process_game_round 
	# DESC: (so we can show WINNER quickly, instead of letting game contineu to process, explode matches, show msgs, etc!)
	if not is_new_game and CmnFunc.count_locked_cells(hbox_container) == 0:
		await CmnFunc.delay_time(self.get_child(0), Enums.EXPLODE_DELAY)
		handle_game_winner()
		return
	
	# B: Show game messages (ex: "Amazing!")
	emit_signal("board_match_multi", matches.size())
	
	# TODO: FIXME: gem counts need to update faster (they currently update after the animation completes)!!
	# seemingly, this would work fine located here but its not - the UI update requires a frame update i guess?
	signal_game_props_count_gems()
	
	# B: let explode animation run
	await CmnFunc.delay_time(self.get_child(0), Enums.TWEEN_TIME)
	
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
	# Delay: let refill animations above complete 
	# Delay: (otherwise new, matching gems would start exploding before they're even in place!)
	await CmnFunc.delay_time(self.get_child(0), Enums.EXPLODE_DELAY)
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

func handle_game_winner():
	Enums.debug_print("[handle_game_winner]: All unlocked!", Enums.DEBUG_LEVEL.INFO)
	# A: show awesome welcome message
	emit_signal("show_game_msg", "Winner!")
	# B: stop game
	inactivity_timer.stop()
	# C: show overlay winner scene
	emit_signal("show_game_winner")

# === Following are for buttons that are unique to game_space.tscn === #

func debug_make_gem_grid():
	CmnDbg.debug_make_gem_grid(hbox_container, GEM_DICT)
	signal_game_props_count_gems()

func debug_clear_debug_labels():
	CmnDbg.debug_clear_debug_labels(hbox_container)

func debug_unlock_cells():
	CmnDbg.debug_unlock_cells(hbox_container)
