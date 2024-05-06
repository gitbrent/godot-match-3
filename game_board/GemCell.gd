extends Control
class_name GemCell
# VARS
@onready var sprite:Sprite2D = $Sprite2D
@onready var anim_player:AnimationPlayer = $AnimationPlayer
@onready var debug_anim_explode:AnimatedSprite2D = $DebugAnimExplode
@onready var debug_label_sel_num:Label = $DebugLabelSelNum
# PROPS
const SPRITE_SCALE:float = 0.25
var gem_color:Enums.GemColor

func initialize(colorIn: Enums.GemColor):
	# A:
	gem_color = colorIn
	load_texture()
	# B:
	#card_control.connect("card_drag_start", self._on_card_drag_start)
	#card_control.connect("card_drag_ended", self._on_card_drag_ended)
	# C:
	#panel_hover.visible = false

func replace_gem(colorIn: Enums.GemColor):
	play_anim_explode()
	initialize(colorIn)
	call_deferred("drop_in_gem")

func drop_in_gem():
	var DEBUG_SLOW_TIME = 2 # Enums.TWEEN_TIME*4
	await get_tree().create_timer(DEBUG_SLOW_TIME).timeout
	# tween "fall" into place
	var beg_pos = Vector2(sprite.global_position.x, sprite.global_position.y - 64)
	var end_pos = sprite.global_position
	#print("beg_pos: ", beg_pos)
	sprite.global_position = beg_pos
	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "global_position", end_pos, DEBUG_SLOW_TIME)

func load_texture():
	# Construct texture path based on suit and rank
	var texture_path = "res://assets/gems/"
	if gem_color == Enums.GemColor.WHITE:
		texture_path += "characters_0001" + ".png"
	elif gem_color == Enums.GemColor.RED:
		texture_path += "characters_0002" + ".png"
	elif gem_color == Enums.GemColor.YELLOW:
		texture_path += "characters_0003" + ".png"
	elif gem_color == Enums.GemColor.GREEN:
		texture_path += "characters_0005" + ".png"
	elif gem_color == Enums.GemColor.PURPLE:
		texture_path += "characters_0007" + ".png"
	
	# Load and assign texture
	sprite.texture = ResourceLoader.load(texture_path)
	#print("[gem_cell] loaded sprite.texture: ", texture_path)

# =========================================================

func play_selected_anim(selected:bool):
	if selected:
		anim_player.play("selected")
	else:
		anim_player.stop(false)
		sprite.scale.x = SPRITE_SCALE
		sprite.scale.y = SPRITE_SCALE

func play_anim_explode():
	# TODO: play sound
	debug_anim_explode.visible = true
	debug_anim_explode.play("default")
	await get_tree().create_timer(1).timeout
	debug_anim_explode.visible = false

# =========================================================

func debug_show_selnum(num:int):
	if not num or num == 0:
		debug_label_sel_num.visible = false
		debug_label_sel_num.text = "-"
	else:
		debug_label_sel_num.visible = true
		debug_label_sel_num.text = str(num)
