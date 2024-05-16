extends Node
class_name Common

func new_game_explode_replace(hbox:HBoxContainer, colors:Array, delay:float):
	# A:
	for vbox in hbox.get_children():
		for gem_cell in vbox.get_children():
			gem_cell.explode_gem(gem_cell.gem_color, 0)
	
	# B:
	await delay_time(hbox, delay)
	
	# C:
	for vbox in hbox.get_children():
		for gem_cell in vbox.get_children():
			gem_cell.replace_gem(colors[randi() % colors.size()], 1)

func delay_time(node: Node, delay: float) -> void:
	var tnode = node.get_parent()
	var timer = Timer.new()
	timer.wait_time = delay
	timer.one_shot = true
	tnode.add_child(timer)
	timer.start()
	await timer.timeout
	tnode.remove_child(timer)
	timer.queue_free()
