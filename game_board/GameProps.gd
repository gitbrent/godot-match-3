# IDEA: separate utli-type funcs here, just onready whatever we need
# good way to split in godot??
extends Node

@onready var h_box_container = $HBoxContainer

func get_gem_props() -> Dictionary:
	var gem_counts: Dictionary = {
		"WHITE": 0,
		"RED": 0,
		"YELLOW": 0,
		"GREEN": 0,
		"PURPLE": 0
	}
	
	# Assuming HBoxContainer contains VBoxContainers which in turn contain GemCells
	for vbox in h_box_container.get_children():
		for gem_cell in vbox.get_children():
			# Assuming each child of vbox is a GemCell and it has a property 'gem_color'
			var color_key: String = Enums.get_color_name(gem_cell.gem_color)  # Convert enum value to string key
			if color_key in gem_counts:
				gem_counts[color_key] += 1  # Increment the count for this color
	
	return gem_counts
