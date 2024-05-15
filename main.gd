extends Node2D

@onready var game_board_1 = $GameBoard1
@onready var game_board_2 = $GameSpace

func _on_btn_board_1_pressed():
	game_board_1.visible = true

func _on_btn_board_2_pressed():
	game_board_2.visible = true
