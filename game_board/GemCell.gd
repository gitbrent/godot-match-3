extends Control
class_name GemCell
# VARS
@onready var sprite:Sprite2D = $Sprite2D
@onready var anim_player_fx:AnimationPlayer = $AnimPlayerFx
@onready var anim_sprite_explode:AnimatedSprite2D = $AnimSpriteExplode
@onready var debug_label_sel_num:Label = $DebugLabelSelNum
# PROPS
const SPRITE_SCALE:Vector2 = Vector2(0.25, 0.25)
const DROP_OFFSET:int = 64
const EXPLODE_DELAY:int = 2
var gem_color:Enums.GemColor
# Declare and preload textures
var gem_textures: Dictionary = {
	Enums.GemColor.WHITE: preload("res://assets/gems/characters_0001.png"),
	Enums.GemColor.RED: preload("res://assets/gems/characters_0002.png"),
	Enums.GemColor.YELLOW: preload("res://assets/gems/characters_0003.png"),
	Enums.GemColor.GREEN: preload("res://assets/gems/characters_0005.png"),
	Enums.GemColor.PURPLE: preload("res://assets/gems/characters_0007.png")
}

func initialize(colorIn: Enums.GemColor):
	# A:
	gem_color = colorIn
	update_texture()
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
	var beg_pos = Vector2(sprite.global_position.x, sprite.global_position.y - DROP_OFFSET)
	var end_pos = sprite.global_position
	#print("beg_pos: ", beg_pos)
	sprite.global_position = beg_pos
	sprite.visible = true
	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "global_position", end_pos, DROP_TIME)

func update_texture():
	if gem_color in gem_textures:
		sprite.texture = gem_textures[gem_color]
		#print("[gem_cell] loaded sprite.texture: ", texture_path)
	else:
		print("Texture for gem color not found")

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
	
	# A: explode effect (scale down to zero)
	# IMPORTANT: use play/stop or scale wont reset!
	anim_player_fx.play("explode")
	anim_player_fx.stop()
	
	# B: explode animation (exploding sprite)
	anim_sprite_explode.visible = true
	anim_sprite_explode.play("default")
	await get_tree().create_timer(EXPLODE_DELAY).timeout
	anim_sprite_explode.visible = false

# =========================================================

func debug_show_selnum(num:int):
	if not num or num == 0:
		debug_label_sel_num.visible = false
		debug_label_sel_num.text = "-"
	else:
		debug_label_sel_num.visible = true
		debug_label_sel_num.text = str(num)
