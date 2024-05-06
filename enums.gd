extends Node

enum GemColor {
	WHITE,
	RED,
	YELLOW,
	GREEN,
	PURPLE
}

func get_color_name_by_value(value: int) -> String:
	for key in GemColor.keys():
		if GemColor[key] == value:
			return key
	return "Unknown"
