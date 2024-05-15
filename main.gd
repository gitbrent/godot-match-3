extends Node2D

@onready var game_board_1 = $GameBoard1

func _on_btn_board_1_pressed():
	game_board_1.visible = true
