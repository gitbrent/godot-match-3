extends Control
class_name CommonGemControl

# SIGNALS
signal cell_click(gem_cell)
signal drag_start(gem_cell, mouse_position)
signal drag_in_prog(gem_cell, mouse_position)
signal drag_ended(gem_cell)

# HANDLE mouse clicks/drags
# NOTE: `event.global_position` is for mouse events and `event.position` is for touch events
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			emit_signal("cell_click", get_parent())
			emit_signal("drag_start", get_parent(), get_global_mouse_position())
		else:
			emit_signal("drag_ended", get_parent(), get_global_mouse_position())
	elif event is InputEventMouseMotion:
		emit_signal("drag_in_prog", get_parent(), event.global_position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			emit_signal("cell_click", get_parent())
			emit_signal("drag_start", get_parent(), event.position)
		else:
			emit_signal("drag_ended", get_parent(), event.position)
	elif event is InputEventScreenDrag:
		# Use touch delta for smoother dragging
		var touch_delta = event.position - event.get_position_in_parent(self) 
		emit_signal("drag_in_prog", get_parent(), touch_delta)
