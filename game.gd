extends Node2D
# SCENES
@onready var audio_gem_move:AudioStreamPlayer = $AudioGemMove
@onready var game_board:GameBoard = $Board
@onready var game_stats = $GameStats

func _on_board_gem_swapped():
	play_move_sound()
	#GameProps.get_props()
	update_game_props()

func play_move_sound():
	audio_gem_move.play()
	
func update_game_props():
	var brent = game_board.get_gem_props()
	print("brent: ", brent)
	# TODO: name labels, then update base on this
	game_stats.get_child(0).get_child(1).text = "99"

func _on_newgame_button_pressed():
	game_board.new_game()

func _on_btn_clear_debug_labels_pressed():
	game_board.debug_clear_debug_labels()

func _on_btn_make_vert_pressed():
	game_board.debug_make_gem_grid()
	#game_board.debug_make_match_col()
