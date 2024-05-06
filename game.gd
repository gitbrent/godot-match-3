extends Node2D
# SCENES
@onready var audio_stream_player:AudioStreamPlayer = $AudioStreamPlayer
@onready var game_board:GameBoard = $Board

func _on_board_gem_swapped():
	play_move_sound()
	#GameProps.get_props()

func play_move_sound():
	audio_stream_player.play()
	
func update_game_props():
	var brent = game_board.get_gem_props()
	print("brent: ", brent)
	# TODO: name labels, then update base on this

func _on_newgame_button_pressed():
	game_board.new_game()
