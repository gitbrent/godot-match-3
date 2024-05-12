extends Control
class_name GemCell
# VARS
@onready var sprite:Sprite2D = $Sprite2D
@onready var anim_player_fx:AnimationPlayer = $AnimPlayerFx
@onready var anim_sprite_explode:AnimatedSprite2D = $AnimSpriteExplode
@onready var debug_label_sel_num:Label = $DebugLabelSelNum
@onready var debug_ui_panel:Panel = $DebugUIPanel
@onready var audio_gem_explode:AudioStreamPlayer = $AudioGemExplode
@onready var audio_gem_move:AudioStreamPlayer = $AudioGemMove
@onready var label_points:Label = $LabelPoints
# PROPS
const SPRITE_SCALE:Vector2 = Vector2(0.5, 0.5)
const DROP_OFFSET:int = 128 # (the sprite is centered in the 128x128 container, and uses a 64,64 position)
var gem_color:Enums.GemColor
# Declare and preload textures
var gem_textures: Dictionary = {
	Enums.GemColor.WHITE: preload("res://assets/gems/characters_0001.png"),
	Enums.GemColor.RED: preload("res://assets/gems/characters_0002.png"),
	Enums.GemColor.YELLOW: preload("res://assets/gems/characters_0003.png"),
	Enums.GemColor.GREEN: preload("res://assets/gems/characters_0005.png"),
	Enums.GemColor.BROWN: preload("res://assets/gems/characters_0006.png"),
	Enums.GemColor.PURPLE: preload("res://assets/gems/characters_0007.png")
}

func initialize(colorIn: Enums.GemColor):
	# A:
	gem_color = colorIn
	# B:
	update_texture()
	# C:
	#panel_hover.visible = false

func explode_gem(colorIn: Enums.GemColor, pointsIn:int):
	# A: set color immediately so code in `GameBoard.gd` canstart checking this cell's color
	gem_color = colorIn
	# B:
	play_selected_anim(false)
	play_anim_explode(pointsIn)

func replace_gem(colorIn: Enums.GemColor, rows_to_drop: int = 1):
	#print("[replace_gem]: colorIn=", colorIn, " rows_to_drop=", rows_to_drop)
	
	# Calculate the beginning position based on how many rows the gem needs to drop
	var drop_height = DROP_OFFSET * rows_to_drop
	# DEBUG!!! vfvvvvvvvv
	debug_ui_panel.get_child(0).get_child(0).text = "drop-ROWS"
	debug_ui_panel.get_child(0).get_child(1).text = str(rows_to_drop)
	debug_ui_panel.get_child(0).get_child(2).text = "drop-H"
	debug_ui_panel.get_child(0).get_child(3).text = str(round(drop_height))
	# DEBUG!!! ^^
	
	var beg_pos = Vector2(sprite.position.x, sprite.position.y - drop_height)
	sprite.position = beg_pos

	# Initialize the gem with the new color and ensure it's visible
	initialize(colorIn)
	sprite.visible = true  # Make sure the sprite is visible if it was hidden after explosion

	# Call the drop animation deferred to ensure it starts after other logic
	call_deferred("drop_in_gem", drop_height)

func drop_in_gem(drop_height: float):
	# Tween the "fall" animation from the starting point to the final position
	var end_pos = Vector2(sprite.position.x, sprite.position.y + drop_height)
	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "position", end_pos, Enums.TWEEN_TIME)

func update_texture():
	if gem_color in gem_textures:
		sprite.texture = gem_textures[gem_color]
		#print("[gem_cell] loaded sprite.texture: ", gem_color)
	else:
		print("ERROR: Texture for gem color not found")

# =========================================================

func play_audio_gem_move():
	audio_gem_move.play()

func play_selected_anim(selected:bool):
	if selected:
		anim_player_fx.play("selected")
	else:
		anim_player_fx.stop()
		sprite.scale = SPRITE_SCALE
		label_points.visible = false

# @desc: both AnimPlayer & AnimExplode are 1-sec
func play_anim_explode(points:int):
	# A: sound effect
	audio_gem_explode.play()
	
	# B: explode effect (scale down to zero)
	# IMPORTANT: use play/stop or scale wont reset!
	anim_player_fx.play("explode")
	sprite.visible = false
	
	# C: show points
	label_points.text = "+"+str(points)
	anim_player_fx.play("new_points")
	
	# D: explode animation (exploding sprite)
	anim_sprite_explode.visible = true
	anim_sprite_explode.play("default")
	await get_tree().create_timer(Enums.EXPLODE_DELAY).timeout
	
	# LAST: reset anim-player effects (after await above)
	anim_sprite_explode.visible = false
	anim_player_fx.stop()
	label_points.visible = false # anim_player_fx stop/reset above unhides it
	
# =========================================================

func debug_show_selnum(num:int):
	if not num or num == 0:
		debug_label_sel_num.visible = false
		debug_label_sel_num.text = "-"
	else:
		debug_label_sel_num.visible = true
		debug_label_sel_num.text = str(num)

func debug_show_debug_panel(isShow:bool):
	debug_ui_panel.visible = isShow
	if not isShow:
		debug_ui_panel.get_child(0).get_child(0).text = "."
		debug_ui_panel.get_child(0).get_child(1).text = "."
		debug_ui_panel.get_child(0).get_child(2).text = "."
		debug_ui_panel.get_child(0).get_child(3).text = "."
