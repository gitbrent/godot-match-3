extends Node2D

@onready var game_board_1 = $GameFood
@onready var game_board_2 = $GameSpace

func _on_btn_board_1_pressed():
	game_board_1.visible = true
	game_board_2.visible = false
	game_board_1.init_game()

func _on_btn_board_2_pressed():
	game_board_1.visible = false
	game_board_2.visible = true
	game_board_2.init_game()
