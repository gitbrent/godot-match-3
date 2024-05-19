extends Node

const APP_VER:String = "0.5.0"
const APP_BLD:String = "20240519"
const TWEEN_TIME:float = 0.25
const EXPLODE_DELAY:float = TWEEN_TIME*2.0
const SRPITE_POS:Vector2 = Vector2(64,64)
var current_debug_level = DEBUG_LEVEL.INFO  # Global variable to set the current debug level

# =========================================================

enum GemColor {
	RED,
	ORG,
	YLW,
	GRN,
	BLU,
	PRP
}

func get_color_name_by_value(value: int) -> String:
	for key in GemColor.keys():
		if GemColor[key] == value:
			return key
	return "Unknown"

# =========================================================

enum GemDict {
	FOOD,
	GEMS,
	SPACE
}

# =========================================================

enum DEBUG_LEVEL {
	NONE,    # No debug output
	ERROR,   # Critical errors only
	WARNING, # Errors and warnings
	INFO,    # Informational output
	DEBUG    # All debug messages
}

func debug_print(message: String, level: int):
	if level <= current_debug_level:
		print(message)
