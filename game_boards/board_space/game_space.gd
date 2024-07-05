extends Node2D
# VARS
var CmnFunc = preload("res://game_boards/all_common/common.gd").new()
# SCENES
@onready var game_top_h_box:HBoxContainer = $ContTopBar/GameTopHBox
@onready var game_stats:VBoxContainer = $ContGameStats/GameStats
@onready var game_board:GemBoardSpace = $ContBoard/GemBoard
@onready var animation_player:AnimationPlayer = $ContMessages/AnimationPlayer
@onready var center_container:CenterContainer = $ContMessages/CenterContainer
@onready var label_msg_btm:RichTextLabel = $ContMessages/CenterContainer/LabelMsgBtm
@onready var label_msg_top:RichTextLabel = $ContMessages/CenterContainer/LabelMsgTop
@onready var cont_winner:Control = $ContWinner
@onready var audio_winner:AudioStreamPlayer = $AudioWinner
@onready var cont_msg_howto_unlock:Control = $ContMsgHowtoUnlock
@onready var debug_cell_value_4 = $ContDebugCellSel/VBoxContainer/CellValue4
@onready var debug_cell_value_5 = $ContDebugCellSel/VBoxContainer/CellValue5

func _ready():
	# A:
	game_board.connect("props_updated_moves", self._on_props_updated_moves)
	game_board.connect("props_updated_score", self._on_props_updated_score)
	game_board.connect("props_updated_gemsdict", self._on_props_updated_gemsdict)
	game_board.connect("board_match_multi", self._on_board_match_multi)
	game_board.connect("show_game_msg", self._on_show_game_msg)
	game_board.connect("show_game_winner", self._on_show_game_winner)
	# B:
	center_container.visible = false
	cont_winner.visible = false

# =========================================================

func _on_props_updated_gemsdict(gems_dict:Dictionary):
	# EX: `{ "RED": 9, "ORG": 11, "YLW": 14, "GRN": 9, "BLU": 9, "PRP": 12 }`
	game_stats.get_child(0).get_child(1).text = str(gems_dict["RED"])
	game_stats.get_child(1).get_child(1).text = str(gems_dict["ORG"])
	game_stats.get_child(2).get_child(1).text = str(gems_dict["YLW"])
	game_stats.get_child(3).get_child(1).text = str(gems_dict["GRN"])
	game_stats.get_child(4).get_child(1).text = str(gems_dict["BLU"])
	game_stats.get_child(5).get_child(1).text = str(gems_dict["PRP"])

func _on_props_updated_score(score:int):
	game_top_h_box.get_child(0).get_child(1).text = str(score)

func _on_props_updated_moves(moves:int):
	game_top_h_box.get_child(1).get_child(1).text = str(moves)

func _on_show_game_msg(msg:String):
	label_msg_btm.text = msg
	label_msg_top.text = msg
	animation_player.play("show_msg_game")
	await CmnFunc.delay_time(self, 0.5)
	center_container.visible = false

func _on_show_game_winner():
	cont_winner.visible = true
	audio_winner.play(0.9)

func _on_board_match_multi(match_cnt:int):
	# TODO: add more messages
	if match_cnt >= 2:
		animation_player.play("show_msg_amazing")

func _on_btn_newgame_pressed():
	cont_winner.visible = false
	game_board.new_game()

func _on_btn_quit_game():
	# TODO: 20240515: convert to `signal()` for Main.tscn to hide all boards, etc.
	visible = false

func _on_btn_checkerboard():
	game_board.debug_make_gem_grid()
	#game_board.debug_make_match_col()

func _on_btn_debug_pressed():
	game_board.debug_clear_debug_labels()

func _on_btn_unlock_pressed():
	game_board.debug_unlock_cells()

func _on_btn_unlock_msg_ok_pressed():
	cont_msg_howto_unlock.visible = false

func _on_btn_clear_debug_cell_pressed():
	debug_cell_value_4.text = "-"
	debug_cell_value_5.text = "-"

# =========================================================

func init_game():
	game_board.init_game()
	cont_msg_howto_unlock.visible = true
