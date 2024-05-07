extends Control
class_name GemCell
# VARS
@onready var sprite:Sprite2D = $Sprite2D
@onready var anim_player_fx:AnimationPlayer = $AnimPlayerFx
@onready var anim_sprite_explode:AnimatedSprite2D = $AnimSpriteExplode
@onready var debug_label_sel_num:Label = $DebugLabelSelNum
# PROPS
const SPRITE_SCALE:Vector2 = Vector2(0.25, 0.25)
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
	# 1:
	play_selected_anim(false)
	play_anim_explode()
	# 2:
	#sprite.scale = SPRITE_SCALE # reset as AnimationPlayer scales it down during explode
	sprite.visible = false # hide Sprite before initialize replaces the texture
	# 3:
	initialize(colorIn)
	# 4:
	call_deferred("drop_in_gem")

func drop_in_gem():
	const DROP_TIME = Enums.TWEEN_TIME * 2
	await get_tree().create_timer(DROP_TIME).timeout
	# tween "fall" into place
	var beg_pos = Vector2(sprite.global_position.x, sprite.global_position.y - 64)
	var end_pos = sprite.global_position
	#print("beg_pos: ", beg_pos)
	sprite.global_position = beg_pos
	sprite.visible = true
	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "global_position", end_pos, DROP_TIME)

# TODO: 20240506: preload these/elevate code
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
		anim_player_fx.play("selected")
	else:
		anim_player_fx.stop()
		sprite.scale = SPRITE_SCALE

# @desc: both AnimPlayer & AnimExplode are 1-sec
func play_anim_explode():
	# TODO: play sound
	# A: IMPORTANT: use play/stop or scale wont reset!
	anim_player_fx.play("explode")
	anim_player_fx.stop()
	# B:
	anim_sprite_explode.visible = true
	anim_sprite_explode.play("default")
	await get_tree().create_timer(2).timeout
	anim_sprite_explode.visible = false

# =========================================================

func debug_show_selnum(num:int):
	if not num or num == 0:
		debug_label_sel_num.visible = false
		debug_label_sel_num.text = "-"
	else:
		debug_label_sel_num.visible = true
		debug_label_sel_num.text = str(num)
