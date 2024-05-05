extends Node2D

@onready var audio_stream_player:AudioStreamPlayer = $AudioStreamPlayer

func _on_board_gem_swapped():
	play_move_sound()

func play_move_sound():
	audio_stream_player.play()
