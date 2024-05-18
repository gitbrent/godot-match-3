extends Control
class_name CommonGemControl
# SIGNALS
signal cell_click(gem_cell)
#signal drag_start(gem_cell, mouse_position)
#signal drag_in_prog(gem_cell)
signal drag_ended(gem_cell)

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			emit_signal("cell_click", get_parent())
			#emit_signal("drag_start", get_parent(), get_global_mouse_position())
		else:
			emit_signal("drag_ended", get_parent())
	elif event is InputEventMouseMotion:
		#emit_signal("drag_in_prog", get_parent(), event.global_position)
		#print("TODO: drag")
		pass
