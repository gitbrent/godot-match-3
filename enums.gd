extends Node

const TWEEN_TIME:float = 0.25
const EXPLODE_DELAY:int = 1

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

# =========================================================

enum DEBUG_LEVEL {
	NONE,    # No debug output
	ERROR,   # Critical errors only
	WARNING, # Errors and warnings
	INFO,    # Informational output
	DEBUG    # All debug messages
}

# Global or class-level variable to set the current debug level
var current_debug_level = DEBUG_LEVEL.DEBUG

func debug_print(message: String, level: int):
	if level <= current_debug_level:
		print(message)
