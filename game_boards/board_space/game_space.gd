extends Node2D
# SCENES
@onready var game_top_h_box:HBoxContainer = $ContTopBar/GameTopHBox
@onready var game_stats:VBoxContainer = $ContGameStats/GameStats
@onready var game_board:GemBoardSpace = $ContBoard/GemBoard
@onready var animation_player:AnimationPlayer = $ContMessages/AnimationPlayer

func _ready():
	game_board.connect("props_updated_moves", self._on_props_updated_moves)
	game_board.connect("props_updated_score", self._on_props_updated_score)
	game_board.connect("props_updated_gemsdict", self._on_props_updated_gemsdict)
	game_board.connect("board_match_multi", self.on_board_match_multi)

func _on_props_updated_gemsdict(gems_dict:Dictionary):
	# EX: `{ "WHITE": 9, "RED": 11, "YELLOW": 14, "BROWN": 9, "GREEN": 9, "PURPLE": 12 }`
	game_stats.get_child(0).get_child(1).text = str(gems_dict["WHITE"])
	game_stats.get_child(1).get_child(1).text = str(gems_dict["RED"])
	game_stats.get_child(2).get_child(1).text = str(gems_dict["YELLOW"])
	game_stats.get_child(3).get_child(1).text = str(gems_dict["GREEN"])
	game_stats.get_child(4).get_child(1).text = str(gems_dict["PURPLE"])
	game_stats.get_child(5).get_child(1).text = str(gems_dict["BROWN"])

func _on_props_updated_score(score:int):
	game_top_h_box.get_child(0).get_child(1).text = str(score)

func _on_props_updated_moves(moves:int):
	game_top_h_box.get_child(1).get_child(1).text = str(moves)

func on_board_match_multi(match_cnt:int):
	# TODO: add more messages
	if match_cnt >= 2:
		animation_player.play("show_msg_amazing")

func _on_btn_newgame_pressed():
	game_board.new_game()

func _on_btn_quit_game():
	# TODO: 20240515: convert to `signal()` for Main.tscn to hide all boards, etc.
	visible = false

func _on_btn_checkerboard():
	game_board.debug_make_gem_grid()
	#game_board.debug_make_match_col()