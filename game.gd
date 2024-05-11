extends Node2D
# SCENES
@onready var game_board:GameBoard = $Board
@onready var game_stats:VBoxContainer = $GameStats

func _ready():
	game_board.connect("props_updated_moves", self._on_props_updated_moves)
	game_board.connect("props_updated_score", self._on_props_updated_score)

func _on_props_updated_moves(moves:int):
	# TODO: name labels, then update base on this
	game_stats.get_child(0).get_child(1).text = str(moves)

func _on_props_updated_score(score:int):
	# TODO: name labels, then update base on this
	game_stats.get_child(1).get_child(1).text = str(score)
	game_stats.get_child(2).get_child(1).text = str(score)

func _on_newgame_button_pressed():
	game_board.new_game()

func _on_btn_clear_debug_labels_pressed():
	game_board.debug_clear_debug_labels()

func _on_btn_make_vert_pressed():
	game_board.debug_make_gem_grid()
	#game_board.debug_make_match_col()
