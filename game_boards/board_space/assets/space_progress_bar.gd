extends Node2D
class_name SpaceProgressBar
@onready var progress_bar = $ProgressBar

func _ready():
	progress_bar.value = 0

func set_progbar(new_value:int):
	progress_bar.value = new_value
